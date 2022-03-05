{
    'name': "Magusiak IT Services SRL",
    'version': '1.0',
    'author': 'Krzysztof Magusiak',
    'category': 'category',
    'license': 'GPL-3',  # no MIT?
    'depends': [
        # Odoo modules
        'base',
        'account',  # simple invoicing
        'contacts',  # contact management
        'l10n_be',  # Belgium
        # 'fleet', # (for car management)
        # OCA
        # 'account_financial_report',  # not needed
    ],
    'data': [
        'data/res_company.xml',
    ]
}
