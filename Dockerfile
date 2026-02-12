ARG BASE_IMAGE=registry.cn-hangzhou.aliyuncs.com/library/python:3.11-slim-bookworm
FROM ${BASE_IMAGE}

ARG DEV_ENV
ARG APT_MIRROR=mirrors.tuna.tsinghua.edu.cn
ARG PIP_INDEX_URL=https://pypi.tuna.tsinghua.edu.cn/simple
ARG PIP_TRUSTED_HOST=pypi.tuna.tsinghua.edu.cn

WORKDIR /src

COPY . /src
COPY ./docker/entrypoint.sh /entrypoint.sh
COPY ./docker/server.ini /docker_server.ini

RUN sed -i "s|deb.debian.org|${APT_MIRROR}|g; s|security.debian.org|${APT_MIRROR}|g" /etc/apt/sources.list.d/debian.sources \
    && apt-get update && apt-get install -y curl --no-install-recommends python3-dev build-essential libgdk-pixbuf2.0-0 \
    libpq-dev libsasl2-dev libldap2-dev libssl-dev libmagic1 redis-tools netcat-traditional \
    && pip install -U pip --no-cache-dir -i ${PIP_INDEX_URL} --trusted-host ${PIP_TRUSTED_HOST} \
    && rm -rf /var/lib/{apt,dpkg,cache,log}/ \
    && chmod +x /entrypoint.sh

# Build development environment if DEV_ENV is true:
# - Install package in editable mode (-e flag) to allow live code changes
# - Keep source code for development
# Otherwise for production:
# - Install package normally
# - Remove source code to reduce image size
RUN if [ ! -z "$DEV_ENV" ]; then \
    echo "Building dev environment ..." && \
    pip install -e . --no-cache-dir -i ${PIP_INDEX_URL} --trusted-host ${PIP_TRUSTED_HOST}; \
    else \
    pip install . --no-cache-dir -i ${PIP_INDEX_URL} --trusted-host ${PIP_TRUSTED_HOST} && rm -rf /src; \
    fi

WORKDIR /home/faraday

RUN mkdir -p /home/faraday/.faraday/config \
    && mkdir -p /home/faraday/.faraday/logs \
    && mkdir -p /home/faraday/.faraday/session \
    && mkdir -p /home/faraday/.faraday/storage

ENV PYTHONUNBUFFERED=1
ENV FARADAY_HOME=/home/faraday
