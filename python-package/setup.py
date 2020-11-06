""" Package description """

import setuptools

from package_name import __version__


setuptools.setup(
    name="pennyworth",
    version=__version__,
    author="HealthVerity",
    author_email="info@healthverity.com",
    description="Package description",
    url="https://github.com/healthverity/pennyworth",
    packages=('package_name',),
    install_requires=(),
    python_requires='>=3'
)
