{
    'name': "Template Report",
    'version': '1.0',
    'author': 'Krzysztof Magusiak',
    'category': 'category',
    'license': 'GPL-3',
    'depends': [
        # Odoo modules
        'base',
        'sale',
    ],
    'data': [
        'security/ir.model.access.csv',
        'reports/report.xml',
    ],
}
