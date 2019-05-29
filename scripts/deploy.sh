#!/usr/bin/env bash


CF_API=`cf api | head -1 | cut -c 25-`

# Deploy services
if [[ $CF_API == *"api.run.pivotal.io"* ]]; then
    cf create-service cleardb spark fortunes-db
    cf create-service p-config-server trial fortunes-config-server -c '{"git": { "uri": "https://github.com/ciberkleid/fortune-teller", "searchPaths": "configuration" } }'
    cf create-service p-service-registry trial fortunes-service-registry
    cf create-service p-circuit-breaker-dashboard trial fortunes-circuit-breaker-dashboard
    cf create-service cloudamqp lemur fortunes-cloud-bus
else
    if [ ! -z "`cf m | grep "p\.config-server"`" ]; then
      export service_name="p.config-server"
      export config_json="{\"git\": { \"uri\": \"https://github.com/ciberkleid/fortune-teller\", \"searchPaths\": \"configuration\" } }"
    elif [ ! -z "`cf m | grep "p-config-server"`" ]; then
      export service_name="p-config-server"
      export config_json="{\"skipSslValidation\": true, \"git\": { \"uri\": \"https://github.com/ciberkleid/fortune-teller\", \"searchPaths\": \"configuration\" } }"
    else
      echo "Can't find SCS Config Server in marketplace. Have you installed the SCS Tile?"
      exit 1;
    fi

    cf cs p.mysql db-small fortunes-db
    cf cs $service_name standard fortunes-config-server -c "$config_json"
    cf cs p-service-registry standard fortunes-service-registry
    cf cs p-circuit-breaker-dashboard standard fortunes-circuit-breaker-dashboard
    cf create-service p.rabbitmq single-node-3.7 fortunes-cloud-bus
fi

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





