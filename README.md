<a href="https://push-to.cfapps.io?repo=https%3A%2F%2Fgithub.com%2Fciberkleid%2Ffortune-teller.git">
 	<img src="https://push-to.cfapps.io/ui/assets/images/Push-to-Pivotal-Light.svg" width="200" alt="Push">
</a>


## Or deploy manually:

Deploy:
```
./mvnw clean package
./scripts/deploy.sh
```

Demo:
- open fortune-ui in a browser - show that fortune-ui returns a variety of fortunes in random order
- stop fortune-service
- show that fortune-ui now returns the fallback fortune obtained through the config server
- update value of fallbackFortune in [configuration/application.yml](configuration/application.yml)
- force config refresh using `curl -X POST https://<YOUR-FORTUNE_UI_URL>/actuator/refresh`
- show that fortune-ui now returns the updated fallback fortune

Clean Up:
```
./scripts/undeploy.sh
```