{
    'name': "Car TCO",
    'version': '1.0',
    'author': 'Krzysztof Magusiak',
    'category': 'category',
    'license': 'GPL-3',  # no MIT?
    'depends': [
        # Odoo modules
        'base',
        # 'fleet', # (for car management)
    ],
    'data': [
        'views/tco_view.xml',
    ],
}
