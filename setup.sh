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
sed -i "/environment =/s/=.*/= INFLUX_ORG=\"${org}\",INFLUX_ACCESS_TOKEN=\"${token}\"/" /etc/supervisor/conf.d/supervisord.conf

# use predefined template configuration
# template from here: https://github.com/influxdata/community-templates/tree/master/thing_network
influx apply -o ${org} -f /etc/influxdb/ttn-template.yml --force yes

supervisorctl reread
supervisorctl update

supervisorctl restart all

touch /setup_done
