# You will want to update the image to use a specific version of the alpine image
FROM python:alpine

WORKDIR /app

COPY requirements.txt .
COPY test/test-requirements.txt test/test-requirements.txt
RUN pip install requirements.txt
RUN pip install test/test-requirements.txt
