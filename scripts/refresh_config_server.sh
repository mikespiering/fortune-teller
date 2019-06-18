#!/usr/bin/env bash

cf update-service fortunes-config-server -c '{"update-git-repos": true }'

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
