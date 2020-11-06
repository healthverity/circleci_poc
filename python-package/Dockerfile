FROM python:alpine

WORKDIR /pkg

COPY test/test-requirements.txt test/test-requirements.txt
COPY ./setup.py .
COPY ./package_name/__init__.py ./package_name/__init__.py

RUN pip install .
RUN pip install test/test-requirements.txt
