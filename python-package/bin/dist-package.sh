#!/bin/bash

set -e

if [ -z "$VERSION" ]; then
    echo 'ERROR: Missing VERSION in environment'
    exit 1
fi

if ! grep $VERSION pennyworth/__init__.py; then
    echo "ERROR: pennyworth.__version__ is not at ${VERSION}"
    exit 1
fi

echo "Publishing python package version ${VERSION}"

python setup.py sdist


S3_LOCATION="s3://healthveritylibs/python/package_name/${VERSION}.tgz"
/usr/local/bin/aws s3 cp dist/package_name-${VERSION}.tar.gz ${S3_LOCATION}


echo "Published plugin to ${S3_LOCATION}"
