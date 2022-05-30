#!/usr/bin/env python3

# This file was customly adapted from OCA's maintainer tools

"""
Usage: odoo-getaddons [-m] path1 [path2 ...]
Given a list  of paths, finds and returns a list of valid addons paths.
With -m flag, will return a list of modules names instead.
"""

import ast
import os
import sys

MANIFEST_FILES = [
    '__manifest__.py',
    '__odoo__.py',
    '__openerp__.py',
    '__terp__.py',
]


def is_module(path):
    """return False if the path doesn't contain an odoo module, and the full
    path to the module manifest otherwise"""

    if not os.path.isdir(path):
        return False
    files = os.listdir(path)
    filtered = [x for x in files if x in (MANIFEST_FILES + ['__init__.py'])]
    if len(filtered) == 2 and '__init__.py' in filtered:
        return os.path.join(path, next(x for x in filtered if x != '__init__.py'))
    else:
        return False


def get_modules(path, depth=1):
    """Return modules of path repo"""
    return sorted(list(get_modules_info(path, depth).keys()))


def get_modules_info(path, depth=1):
    """Return a digest of each installable module's manifest in path repo"""
    # Avoid empty basename when path ends with slash
    if not os.path.basename(path):
        path = os.path.dirname(path)

    modules = {}
    if os.path.isdir(path) and depth > 0:
        for module in os.listdir(path):
            manifest_path = is_module(os.path.join(path, module))
            if manifest_path:
                manifest = ast.literal_eval(open(manifest_path).read())
                if manifest.get('installable', True):
                    modules[module] = {
                        'application': manifest.get('application'),
                        'depends': manifest.get('depends') or [],
                        'auto_install': manifest.get('auto_install'),
                    }
            else:
                deeper_modules = get_modules_info(os.path.join(path, module), depth - 1)
                modules.update(deeper_modules)
    return modules


def is_addons(path):
    res = get_modules(path) != []
    return res


def get_addons(path, depth=1):
    """Return repositories in path. Can search in inner folders as depth."""
    if not os.path.exists(path) or depth < -1:
        return []
    res = []
    if is_addons(path):
        res.append(path)
    else:
        new_paths = [
            os.path.join(path, x)
            for x in sorted(os.listdir(path))
            if os.path.isdir(os.path.join(path, x))
        ]
        for new_path in new_paths:
            res.extend(get_addons(new_path, depth - 1))
    return res


def get_dependencies(modules, module_name):
    """Return a set of all the dependencies in deep of the module_name.
    The module_name is included in the result."""
    result = set()
    for dependency in modules.get(module_name, {}).get('depends', []):
        result |= get_dependencies(modules, dependency)
    return result | set([module_name])


def get_dependents(modules, module_name):
    """Return a set of all the modules that are dependent of the module_name.
    The module_name is included in the result."""
    result = set()
    for dependent in modules.keys():
        if module_name in modules.get(dependent, {}).get('depends', []):
            result |= get_dependents(modules, dependent)
    return result | set([module_name])


def add_auto_install(modules, to_install):
    """Append automatically installed glue modules to to_install if their
    dependencies are already present. to_install is a set."""
    found = True
    while found:
        found = False
        for module, module_data in modules.items():
            if (
                module_data.get('auto_install')
                and module not in to_install
                and all(dependency in to_install for dependency in module_data.get('depends', []))
            ):
                found = True
                to_install.add(module)
    return to_install


def get_applications_with_dependencies(modules):
    """Return all modules marked as application with their dependencies.
    For our purposes, l10n modules cannot be an application."""
    result = set()
    for module, module_data in modules.items():
        if module_data.get('application') and not module.startswith('l10n_'):
            result |= get_dependencies(modules, module)
    return add_auto_install(modules, result)


def get_localizations_with_dependents(modules):
    """Return all localization modules with the modules that depend on them"""
    result = set()
    for module in modules.keys():
        if module.startswith('l10n_'):
            result |= get_dependents(modules, module)
    return result


def main(argv=None):
    import argparse

    parser = argparse.ArgumentParser(description="Given a list of paths, find addons paths")
    parser.add_argument(
        '-m', '--modules',  metavar='depth', type=int, nargs='?', const=1,
        help="List the module names instead of paths",
    )
    parser.add_argument('--only-applications', dest='application', action='store_const', const=True)
    parser.add_argument('--exclude-applications', dest='application', action='store_const', const=False)
    parser.add_argument('--only-localizations', dest='localization', action='store_const', const=True)
    parser.add_argument('--exclude-localizations', dest='localization', action='store_const', const=False)
    parser.add_argument('-e', '--exclude', dest='exclude')
    parser.add_argument('paths', metavar='path', nargs='+')
    if argv is None:
        argv = sys.argv[1:]
    args = parser.parse_args(argv)

    list_modules_depth = args.modules
    exclude_modules = args.exclude.split(',') if args.exclude else []
    paths = args.paths

    if list_modules_depth:
        modules = {}
        for path in paths:
            modules.update(get_modules_info(path, depth=list_modules_depth))
        res = set(modules.keys())
        applications, localizations = set(), set()
        if isinstance(args.application, bool):
            applications = get_applications_with_dependencies(modules)
            if not args.application:
                res -= applications
                applications = set()
        if isinstance(args.localization, bool):
            localizations = get_localizations_with_dependents(modules)
            if not args.localization:
                res -= localizations
                localizations = set()
        if args.application or args.localization:
            res = applications | localizations
        res = sorted(list(res))
    else:
        lists = [get_addons(path) for path in paths]
        res = [x for ls in lists for x in ls]  # flatten list of lists
    if exclude_modules:
        res = [x for x in res if x not in exclude_modules]
    print(','.join(res))


if __name__ == "__main__":
    sys.exit(main())
