# -*- coding: utf-8 -*-

# Copyright (c) 2020 shmilee

import os
from setuptools import setup, find_packages

here = os.path.abspath(os.path.dirname(__file__))
with open(os.path.join(here, 'README.rst'), encoding='utf-8') as f:
    long_description = '\n' + f.read()

setup(
    name='netinfocap',
    version='0.9.5',
    description='Netinfo Capture',
    long_description=long_description,
    long_description_content_type='text/x-rst',
    author='shmilee',
    url='https://github.com/shmilee/scripts/netinfocap',
    license='MIT',
    keywords='Netinfo, pyshark',
    package_dir={'netinfocap': 'netinfocap'},
    packages=find_packages(where=here),
    platforms=[
        'Linux',
    ],
    classifiers=[
        'Development Status :: 4 - Beta',
        'Environment :: Console',
        'Intended Audience :: Other Audience',
        'License :: OSI Approved :: MIT License',
        'Operating System :: POSIX :: Linux',
        'Programming Language :: Python',
        'Programming Language :: Python :: 3.5',
        'Programming Language :: Python :: 3.6',
        'Programming Language :: Python :: 3.7',
        'Programming Language :: Python :: 3.8',
        'Programming Language :: Python :: 3.9',
        'Topic :: Internet',
        'Topic :: Multimedia :: Video'
    ],
    install_requires=[
        'pyshark>=0.4.0',
        'py>=1.11.0',
        'requests>=2.0.0',
    ] + [
        # video-thumbnails,
        # for sub package vcsi from 'https://github.com/amietn/vcsi'
        'numpy', 'pillow', 'jinja2', 'texttable', 'parsedatetime',
    ],
    extras_require={},
    package_data={},
    data_files=[],
    entry_points={
        'console_scripts': [
            'netinfocap = netinfocap.__main__:main',
            'netinfocap-json2html = netinfocap.convert_json:main',
            'netinfocap-vcsi = netinfocap.vcsi:main',
        ],
    },
)
