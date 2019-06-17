#!/bin/bash

# delete apps
cf delete fortune-service -f
cf delete fortune-ui -f

# delete services
cf delete-service fortunes-db -f
cf delete-service fortunes-config-server -f
cf delete-service fortunes-service-registry -f
cf delete-service fortunes-cloud-bus -f

# delete routes
cf delete-orphaned-routes -f
