#!/usr/bin/env bash

CF_API=`cf api | head -1 | cut -c 25-`

if [[ $CF_API == *"api.run.pivotal.io"* ]]; then
    export config_json="{\"git\": { \"uri\": \"https://github.com/ciberkleid/fortune-teller\", \"searchPaths\": \"configuration\" } }"
else
    if [ ! -z "`cf m | grep "p\.config-server"`" ]; then
      export config_json="{\"git\": { \"uri\": \"https://github.com/ciberkleid/fortune-teller\", \"searchPaths\": \"configuration\" } }"
    elif [ ! -z "`cf m | grep "p-config-server"`" ]; then
      export config_json="{\"skipSslValidation\": true, \"git\": { \"uri\": \"https://github.com/ciberkleid/fortune-teller\", \"searchPaths\": \"configuration\" } }"
    fi
fi

cf update-service fortunes-config-server -c "$config_json"

# Wait until services are ready
while cf services | grep 'fortunes-config-server' | grep 'update in progress'
do
  sleep 20
  echo "Waiting for config server to update..."
done

# Check to see if any services failed to create
if cf services | grep 'fortunes-config-server' | grep 'failed'; then
  echo "Service update - failed. Exiting."
  return 1
fi
echo "Service update - successful"
