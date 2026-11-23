FROM python:3.12-slim

RUN apt-get update \
 && apt-get install -y --no-install-recommends chromium chromium-driver \
 && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir selenium pytest

WORKDIR /tests
COPY test_site.py /tests/test_site.py

ENV BASE_URL=http://staging
ENV HOME=/tmp
CMD ["pytest", "-v", "--junitxml=/results/results.xml", "/tests/test_site.py"]
