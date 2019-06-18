<a href="https://push-to.cfapps.io?repo=https%3A%2F%2Fgithub.com%2Fciberkleid%2Ffortune-teller.git">
 	<img src="https://push-to.cfapps.io/ui/assets/images/Push-to-Pivotal-Light.svg" width="200" alt="Push">
</a>


## Or deploy manually:

### Deploy:
```
source ./scripts/deploy.sh
```

### Demo:
1. Open fortune-ui in a browser - refresh the page several times and notice that fortune-ui returns a variety of fortunes in random order.

   _**What does this show?** fortune-ui retrieved the endpoint for fortune-service from the Service Registry (Eureka) and is successfully communicating with fortune-service._
2. Stop fortune-service using Apps Manager or `cf stop fortune-service`. Refresh fortune-ui in your browser several times to see that it now repeatedly returns a single static fortune.

   _**What does this show?** fortune-ui is using a Circuit Breaker to gracefully handle the "outage" of fortune-service and return a fallback fortune. Note the corresponding code in fortune-ui's [FortuneService.java](fortune-teller-ui/src/main/java/io/spring/cloud/samples/fortuneteller/ui/services/fortunes/FortuneService.java), which uses @HystrixCommand to create a circuit breaker with a fallback method._
3. Notice that the value of the fallback fortune that fortune-ui is returning in the browser is coming from a [config file](configuration/application.yml) and not from the [fortune-ui code](fortune-teller-ui/src/main/java/io/spring/cloud/samples/fortuneteller/ui/services/fortunes/FortuneProperties.java).

   _**What does this show?** fortune-ui is obtaining configuration from an externalized configuratoin file via Config Server. Note the use of @ConfigurationProperties in [FortuneProperties.java](fortune-teller-ui/src/main/java/io/spring/cloud/samples/fortuneteller/ui/services/fortunes/FortuneProperties.java)._
4. Update the value of fallbackFortune in [configuration/application.yml](configuration/application.yml). Commit & push the change to GitHub.

   _**Note** This step required that you point Config Server to a config repo to which you have write access. You can fork this repo and update the Config Server to point to your forked repo using `cf update-service fortunes-config-server -c "$config_json"`. ($config_json is set when you source the deployment script - check its value and update it to point to your fork URL). Then, use `cf services` to ensure that fortunes-config-server has finished updating before proceeding._
5. If using Config Server 3.x (aka if `cf m | grep "p\.config"` returns a value), you need to trigger the Config Server to update its clone of the GitHub repo. Do this by running `cf update-service fortunes-config-server -c '{"update-git-repos": true }'`. Then, use `cf services` to ensure that fortunes-config-server has finished updating before proceeding.
6. Trigger fortune-ui to obtain the update from Config Server using `curl -X POST -k https://<YOUR-FORTUNE_UI_URL>/actuator/refresh`. Refresh fortune-ui in your browser and notice that it now returns the updated fallbackFortune that you updated in your GitHub repo.

   _**What does this show?** fortune-ui obtained the updated fallbackFortune from Config Server and refreshed the value of fallbackFortune without requiring a restart. Note the use of @RefreshScope in [FortuneProperties.java](fortune-teller-ui/src/main/java/io/spring/cloud/samples/fortuneteller/ui/services/fortunes/FortuneProperties.java)._
7. Scale the fortune-ui app using `cf scale fortune-ui -i 2`. Refresh fortune-ui in your browser several times and notice that the traffic is load balanced across both instances (note the changing value of app instance id displayed on the page).
8. Repeat steps 4-5 (update the fallbackFortune in your GitHub config repo and force the Config Server to update its clone of the repo).
9. Trigger fortune-ui to refresh the value of fallbackFortune in both instances using `curl -X POST -k https://<YOUR-FORTUNE_UI_URL>/actuator/bus-refresh`. Refresh fortune-ui in your browser several times to see that both instances return the updated fallbackFortune.

   _**What does this show?** the bus-refresh endpoint triggered both fortune-ui instances to obtain the updated value from Config Server by publishing a trigger message to the fortunes-cloud-bus._
10. In Apps Manager, navigate to the details page for fortune-ui and click on the link for PCF Metrics. In the PCF Metrics UI, filter the logs using the key work "random". Click on the icon on the left of the search results to open the Distributed Tracing UI. Observe that distributed tracing shows the trajectory of a user request across both fortune-ui and fortune-service.
11. To show fortune-ui discovering fortune-service without using the Service Registry (Eureka), run the following commands. Replace <DOMAIN> and <HOSTNAME> with the appropriate values from your fortune-service URL.
```
cf unbind-service fortune-service fortunes-service-registry
cf unbind-service fortune-ui fortunes-service-registry
cf unmap-route fortune-service <DOMAIN> --hostname <HOSTNAME>
cf map-route fortune-service apps.internal --hostname fortune-teller-fortune-service
cf set-env fortune-service SPRING_PROFILES_ACTIVE mesh
cf set-env fortune-ui SPRING_PROFILES_ACTIVE mesh
cf restage fortune-service
cf restage fortune-ui
cf add-network-policy fortune-ui --destination-app fortune-service --protocol tcp --port 8080
```
11. Refresh fortune-ui in your browser several times to see that both instances return a variety of fortunes in random order.

   _**What does this show?** fortune-ui is using the default internal domain to discover and load balance requests to fortune-service._

### Clean Up:
```
./scripts/undeploy.sh
```
