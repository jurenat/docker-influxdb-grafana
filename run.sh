#!/bin/bash -e

# We need to ensure this directory is writeable on start of the container
chmod 0777 /var/lib/grafana


if [ ! -f /setup_done ]
then
    supervisord &
    sleep 1
    PID=$(supervisorctl pid)
    sleep 2
    source /setup.sh
    kill ${PID}
fi

DEFAULT_INFLUXDB=/etc/default/influxdb2
DEFAULT_TELEGRAF=/etc/default/telegraf
DEFAULT_GRAFANA_SERVER=/etc/default/grafana-server

if [ -r $DEFAULT_INFLUXDB ]
then
    # set -a causes all variables to be auto-exported.
    set -a
    source $DEFAULT_INFLUXDB
    set +a
fi

if [ -r $DEFAULT_TELEGRAF ]
then
    # set -a causes all variables to be auto-exported.
    set -a
    source $DEFAULT_TELEGRAF
    set +a
fi

if [ -r $DEFAULT_GRAFANA_SERVER ]
then
    # set -a causes all variables to be auto-exported.
    set -a
    source $DEFAULT_GRAFANA_SERVER
    set +a
fi

exec /usr/bin/supervisord
