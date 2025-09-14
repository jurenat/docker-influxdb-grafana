FROM ubuntu:noble
LABEL maintainer="Tomas Jurena <jurenatomas@gmail.com>"

ARG DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8

# Default versions
ARG GRAFANA_VERSION=12.1.1
ARG GRAFANA_TS=16903967602

# Grafana database type
ENV GF_DATABASE_TYPE=sqlite3

# Fix bad proxy issue
COPY system/99fixbadproxy /etc/apt/apt.conf.d/99fixbadproxy

WORKDIR /root

SHELL ["/bin/bash", "-c"]

# Clear previous sources
RUN ARCH= && dpkgArch="$(dpkg --print-architecture)" && \
    case "${dpkgArch##*-}" in \
      amd64) ARCH='amd64';; \
      arm64) ARCH='arm64';; \
      armhf) ARCH='armhf';; \
      armel) ARCH='armel';; \
      *)     echo "Unsupported architecture: ${dpkgArch}"; exit 1;; \
    esac \
    && rm /var/lib/apt/lists/* -vf \
    # Base packages
    && apt-get -y update \
    && apt-get -y dist-upgrade \
    && apt-get -y install \
        apt-utils \
        ca-certificates \
        curl \
        git \
        htop \
        libfontconfig \
        nano \
        net-tools \
        supervisor \
        wget \
        gnupg \
        libfontconfig1 \
        adduser \
        musl \
        cron \
        python3-venv \
    && mkdir -p /var/log/supervisor \
    && rm -rf .profile \
    # Install InfluxDB & telegraf
    && wget -q https://repos.influxdata.com/influxdata-archive.key \
    && gpg --show-keys --with-fingerprint --with-colons ./influxdata-archive.key 2>&1 | grep -q '^fpr:\+24C975CBA61A024EE1B631787C3D57159FC2F927:$' && cat influxdata-archive.key | gpg --dearmor | tee /etc/apt/trusted.gpg.d/influxdata-archive.gpg > /dev/null \
    && echo 'deb [signed-by=/etc/apt/trusted.gpg.d/influxdata-archive.gpg] https://repos.influxdata.com/debian stable main' | tee /etc/apt/sources.list.d/influxdata.list \
    && apt-get update \
    && apt-get -y install influxdb2 telegraf \
    # Install Grafana
    && wget -q https://dl.grafana.com/grafana/release/${GRAFANA_VERSION}/grafana_${GRAFANA_VERSION}_${GRAFANA_TS}_linux_${ARCH}.deb -O grafana.deb\
    && dpkg -i grafana.deb \
    && rm grafana.deb \
    # Cleanup
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN python3 -m venv /opt/certbot/ && \
    /opt/certbot/bin/pip install --upgrade pip && \
    /opt/certbot/bin/pip install certbot && \
    ln -s /opt/certbot/bin/certbot /usr/bin/certbot

RUN echo "0 0,12 * * * root /opt/certbot/bin/python -c 'import random; import time; time.sleep(random.random() * 3600)' && certbot renew -q" | tee -a /etc/crontab > /dev/null

# Configure Supervisord and base env
COPY supervisord/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY bash/profile .profile

# Configure InfluxDB
COPY influxdb/influxdb.conf /etc/influxdb/influxdb.conf
COPY influxdb/ttn-template.yml /etc/influxdb/ttn-template.yml

# Configure Telegraf
COPY telegraf/telegraf.conf /etc/telegraf/telegraf.conf

# Configure Grafana
COPY grafana/grafana.ini /etc/grafana/grafana.ini
COPY grafana/provisioning/datasources/influxdb.yml /etc/grafana/provisioning/datasources/influxdb.yml
COPY grafana/provisioning/dashboards/dashboards.yaml /etc/grafana/provisioning/dashboards/dashboards.yaml
COPY grafana/dashboards/Temperature.json  /var/lib/grafana/dashboards/Temperature.json

COPY run.sh /run.sh
COPY setup.sh /setup.sh

RUN ["chmod", "+x", "/run.sh"]
CMD ["/run.sh"]
