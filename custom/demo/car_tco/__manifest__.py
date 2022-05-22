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
        'security/ir.model.access.csv',
        'views/tco_view.xml',
    ],
}
