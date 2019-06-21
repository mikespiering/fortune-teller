# Deploy:

Use the cf CLI to target the org and space into which you want to deploy this demo. Then, run the following commands:
```
git clone https://github.com/ciberkleid/fortune-teller
cd fortune-teller
source ./scripts/deploy.sh
```

# Demo:

#### 1. Service Registry in Action
- Open fortune-ui in a browser. Refresh the page several times and notice that fortune-ui returns a variety of fortunes in random order.

   _**What does this show?** fortune-ui retrieved the endpoint for fortune-service from the Service Registry (Eureka) and is successfully communicating with fortune-service._
#### 2. Circuit Breaker in Action
- Stop fortune-service using Apps Manager or `cf stop fortune-service`. Refresh fortune-ui in your browser several times to see that it now repeatedly returns a single static fortune.

   _**What does this show?** fortune-ui is using a Circuit Breaker to gracefully handle the "outage" of fortune-service and return a fallback fortune. Notice the corresponding code in fortune-ui's [FortuneService.java](fortune-teller-ui/src/main/java/io/spring/cloud/samples/fortuneteller/ui/services/fortunes/FortuneService.java), which uses @HystrixCommand to configure a circuit breaker with a fallback method._
#### 3. Config Server in Action
- Notice that the value of the fallback fortune that fortune-ui is returning in the browser is coming from a [config file](configuration/application.yml) and not from the [fortune-ui code](fortune-teller-ui/src/main/java/io/spring/cloud/samples/fortuneteller/ui/services/fortunes/FortuneProperties.java).

   _**What does this show?** Notice the use of @ConfigurationProperties in [FortuneProperties.java](fortune-teller-ui/src/main/java/io/spring/cloud/samples/fortuneteller/ui/services/fortunes/FortuneProperties.java). fortune-ui is obtaining configuration from an externalized configuratoin file via Config Server._
#### 4. Config Server in Action - Client Refresh (single instance)
- Update the value of fallbackFortune in [configuration/application.yml](configuration/application.yml). Commit & push the change to GitHub.

   _**Note** This step requires that you point Config Server to a git repo to which you have write access. You can fork [this repo](https://github.com/ciberkleid/fortune-teller) and update your existing Config Server instance to point to your forked repo using `cf update-service fortunes-config-server -c "$config_json"`. ($config_json was set when you sourced the deployment script above - check its value using `echo $config_json` and update it to point to your fork's URL). Then, use `cf services` to ensure that fortunes-config-server has finished updating before proceeding._
- If using Config Server 3.x (aka if `cf m | grep "p\.config"` returns a value), you need to trigger the Config Server to update its clone of the GitHub repo. Do this by running `cf update-service fortunes-config-server -c '{"update-git-repos": true }'`. Then, use `cf services` to ensure that fortunes-config-server has finished updating before proceeding.
- Trigger fortune-ui to obtain the updated value from Config Server using the commands below. Then, refresh fortune-ui in your browser and notice that it now returns the updated fallbackFortune that you updated in your GitHub repo.
```
export app_url=`cf app fortune-ui | grep "routes:" | cut -c 20-`
curl -X POST -k https://$app_url/actuator/refresh
```
   _**What does this show?** Notice the use of @RefreshScope in [FortuneProperties.java](fortune-teller-ui/src/main/java/io/spring/cloud/samples/fortuneteller/ui/services/fortunes/FortuneProperties.java). fortune-ui obtained the updated fallbackFortune from Config Server and refreshed the value of fallbackFortune without requiring a restart._
#### 5. Config Server in Action - Client Refresh (all instances)
- Scale the fortune-ui app using `cf scale fortune-ui -i 2`. Refresh fortune-ui in your browser several times and notice that the traffic is load balanced across both instances (note the changing value of the app instance id displayed on the page).
- Repeat the first two bullet points in Step 4 (update the fallbackFortune in your git repo and force the Config Server to update its clone of the config repo).
- Trigger fortune-ui to refresh the value of fallbackFortune by calling the refresh endpoint on each instance individually, as follows:
 ```
export app_url=`cf app fortune-ui | grep "routes:" | cut -c 20-`
export app_guid=`cf app fortune-ui --guid`
curl -X POST -k https://$app_url/actuator/bus-refresh -H "X-CF-APP-INSTANCE":"$app_guid:0"
```
- Refresh fortune-ui in your browser several times to see that one instance returns the updated fallbackFortune. Then trigger the refresh on the second instance:
```
export app_url=`cf app fortune-ui | grep "routes:" | cut -c 20-`
export app_guid=`cf app fortune-ui --guid`
curl -X POST -k https://$app_url/actuator/bus-refresh -H "X-CF-APP-INSTANCE":"$app_guid:1"
```
- Refresh fortune-ui in your browser several times to see that both instances returns the updated fallbackFortune.

   _**What does this show?** You can target each individual instance of fortune-ui to ensure all instances obtain the updated value from Config Server._
#### 6. Config Server in Action - Client Refresh (all instances using message trigger)
- Repeat the first two bullet points in Step 4 (update the fallbackFortune in your git repo and force the Config Server to update its clone of the config repo).
- Trigger fortune-ui to refresh the value of fallbackFortune in both instances, as follows:
```
export app_guid=`cf app fortune-ui --guid`
curl -X POST -k https://$app_url/actuator/bus-refresh
```
- Refresh fortune-ui in your browser several times to see that both instances return the updated fallbackFortune.

   _**What does this show?** The bus-refresh endpoint triggered both fortune-ui instances to obtain the updated value from Config Server by publishing a trigger message to the fortunes-cloud-bus._
#### 7. Distributed Tracing
- In Apps Manager, navigate to the details page for fortune-ui and click on the link for PCF Metrics. In the PCF Metrics UI, filter the logs using the key work "random". Click on the icon on the left of the search results to open the Distributed Tracing UI. Observe that distributed tracing shows the trajectory of a user request across both fortune-ui and fortune-service.
#### 8. Service Discovery using Cloud Foundry Internal Domain
- To show fortune-ui discovering fortune-service without using the Service Registry (Eureka), run the following commands. Replace <DOMAIN> and <HOSTNAME> with the appropriate values from your fortune-service URL.
```
export app2_hostname=`cf app fortune-service | grep "routes:" | cut -c 20- | cut -d "." -f 1`
export app2_domain=`cf app fortune-service | grep "routes:" | cut -c 20- | cut -d "." -f 2,3`
cf unmap-route fortune-service $app2_domain --hostname $app2_hostname
cf map-route fortune-service apps.internal --hostname fortune-teller-fortune-service
cf set-env fortune-service SPRING_PROFILES_ACTIVE mesh
cf set-env fortune-ui SPRING_PROFILES_ACTIVE mesh
cf unbind-service fortune-service fortunes-service-registry
cf unbind-service fortune-ui fortunes-service-registry
cf restage fortune-service
cf restage fortune-ui
cf add-network-policy fortune-ui --destination-app fortune-service --protocol tcp --port 8080
```
- Refresh fortune-ui in your browser several times to see that both instances return a variety of fortunes in random order.

   _**What does this show?** fortune-ui is using the default internal domain to discover and load balance requests to fortune-service._
#### 9. Config Server with CredHub Backend

```
export config_server_url=`cf service fortunes-config-server | grep "dashboard:" | cut -c 19- | cut -d "/" -f 1-3`
curl $config_server_url/secrets/fortune-ui/cloud/master/my-cloud-secret -H "Authorization: $(cf oauth-token)" -X PUT -k --data '{"my-secret-cloud-key": "my-super-secret-cloud-value"}' -H "Content-Type: application/json"
curl -X POST -k https://$app_url/actuator/bus-refresh
```
- Open fortune-ui in your browser and add the path `/actuator/env` to the end of the URL. You will see a property source called `"name": "configService:credhub-fortune-ui"`, and you should see one of the properties matches the one you just inserted. The key is legible, and the value is redacted intentionally.

   _**What does this show?** fortune-ui is using the a composite backend comprising GitHub and CredHub._

# Clean Up:
```
./scripts/undeploy.sh
```