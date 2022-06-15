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

exec /usr/bin/supervisord
