import os
from setuptools import setup, Extension

args = {
    'name' : 'qplex',
    'license' : 'MIT',
    'version' : '@VERSION@',
    'ext_modules' : [Extension('qplex', ['qplex.cpp'])],
    'project_urls' :
        {   'Homepage': 'https://qplex.org/',
            'Documentation': 'https://qplex.org/documentation/',
            'GitHub': 'https://github.com/qplex/qplex-python-package/'
        },
    'description' : 'Performs calculations for models supported by the QPLEX stochastic modeling methodology'
}

filename = 'package-page-readme.rst'
if os.path.exists(filename):
    args['long_description'] = open(filename).read()
    args['long_description_content_type'] = 'text/x-rst'

setup(**args)
