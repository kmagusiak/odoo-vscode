{
    'name': "Template Module",
    'version': '1.0',
    'author': 'Krzysztof Magusiak',
    'category': 'category',
    'license': 'GPL-3',
    'depends': [
        'web',
    ],
    'data': [
        'security/ir.model.access.csv',
        'views/views.xml',
    ],
    'assets': {
        'web.assets_tests': [
            'template_module/static/tests/tours/test_tour.js',
        ],
    },
}
