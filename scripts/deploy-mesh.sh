#!/usr/bin/env bash


CF_API=`cf api | head -1 | cut -c 25-`

# Deploy services
cf cs azure-mysqldb basic1 fortunes-db
export config_json="{\"git\": { \"uri\": \"https://github.com/ciberkleid/fortune-teller\", \"searchPaths\": \"configuration\" } }"
cf cs p.config-server standard fortunes-config-server -c "$config_json"
cf create-service p.rabbitmq single-node-3.7 fortunes-cloud-bus

# Prepare config file to set TRUST_CERTS value
echo "cf_trust_certs: $CF_API" > vars.yml

# Wait until services are ready
while cf services | grep 'create in progress'
do
  sleep 20
  echo "Waiting for services to initialize..."
done

# Check to see if any services failed to create
if cf services | grep 'create failed'; then
  echo "Service initialization - failed. Exiting."
  return 1
fi
echo "Service initialization - successful"

# Push apps
cf push -f manifest.yml --vars-file vars.yml





