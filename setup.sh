#!/bin/bash

org=beehive-org
bucket=beehive-scale

# initialize the influxdb
influx setup \
  --org ${org} \
  --bucket ${bucket} \
  --username beehive \
  --password adminPass \
  --force

# create API tokens
influx auth create --write-buckets --read-buckets -d "Token for telegraf and grafana"
token=$(influx auth list | tail -n 1 | awk '{print $7}')
echo "INFLUX_ORG=\"${org}\"
INFLUX_TOKEN=\"${token}\"
INFLUX_HOST=\"http://localhost:8086\"
INFLUX_BUCKET=\"${bucket}\"" > /etc/default/influxdb2

# use predefined template configuration
# template from here: https://github.com/influxdata/community-templates/tree/master/thing_network
influx apply -o ${org} -f /etc/influxdb/ttn-template.yml --force yes

touch /setup_done
