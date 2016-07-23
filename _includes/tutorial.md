# Tutorial
Following on from the quick start lets have a little deeper look at how Minke actually works.

## Run minke
```bash
$ curl -Ls https://get.minke.rocks | bash -s 'minke'
```

You should see the below output showing the help options and the currently installed generators.

```
888b     d888 d8b          888
8888b   d8888 Y8P          888
88888b.d88888              888
888Y88888P888 888 88888b.  888  888  .d88b.
888 Y888P 888 888 888 "88b 888 .88P d8P  Y8b
888  Y8P  888 888 888  888 888888K  88888888
888   "   888 888 888  888 888 "88b Y8b.
888       888 888 888  888 888  888  "Y8888

Version: 1.12.3

# Loading installed generators
registered minke-generator-go
registered minke-generator-netmvc
registered minke-generator-swift


Usage: minke [options]
    -e, --encrypt STRING             Encrypt a string
    -k, --key STRING                 Private key to use for encryption
    -g, --generator GENERATOR        Generator plugin to use
    -o, --output OUTPUT              Output folder
    -a, --application_name NAME      Application name
    -n, --namespace NAMESPACE        Application namespace
```

## Scaffold a project
We can now scaffold a new go μService using the following command:

```bash
$ curl -Ls https://get.minke.rocks | bash -s ' -g minke-generator-go -o $(pwd) -n github.com/nicholasjackson -a myservice'
```

If look at the output folder we will see something like the below folder structure, all our source code is in the root and there is a **_build** folder, this is where Minke stores things like the Docker and Docker Compose files and configuration.

```
0 drwxr-xr-x   9 nicj  129917615   306 22 Jun 16:31 .
0 drwxr-xr-x  15 nicj  129917615   510 22 Jun 16:30 ..
8 -rw-r--r--   1 nicj  129917615     9 22 Jun 16:31 .gitignore
0 drwxr-xr-x  14 nicj  129917615   476 22 Jun 16:31 _build
0 drwxr-xr-x   3 nicj  129917615   102 22 Jun 16:31 global
0 drwxr-xr-x  10 nicj  129917615   340 22 Jun 16:31 handlers
0 drwxr-xr-x   3 nicj  129917615   102 22 Jun 16:31 logging
8 -rw-r--r--   1 nicj  129917615  1582 22 Jun 16:31 main.go
0 drwxr-xr-x   3 nicj  129917615   102 22 Jun 16:31 mocks
```

## Building and testing your application
Change to the **_build** folder

```
$ cd _build
```
To avoid the pain of having to craft a ridiculously long docker run cmd every time you want to run a command there is a bash script `minke.sh` in the build folder.  This simply runs the commands specified as arguments inside the Minke Docker container.  The parent folder to _build (source root) is mapped as a volume inside the container with the same path as your local folder and the working directory is set to _build folder.

Since Minke is primarily uses Rake you can run `$ ./minke.sh rake -T` to see the various options available to you.

```
rake app:build              # build application
rake app:build_and_run      # build and run application with Docker Compose
rake app:build_image        # build Docker image for application
rake app:cucumber[feature]  # run end to end Cucumber tests USAGE: rake app:cucumber[@tag]
rake app:fetch              # fetch dependent packages
rake app:push               # push built image to Docker registry
rake app:run                # run application with Docker Compose
rake app:test               # run unit tests
rake docker:fetch_images    # pull images for golang from Docker registry if not already downloaded
rake docker:update_images   # updates build images for swagger and golang will overwrite existing images
```

### Building the application
To build the application simply execute:

```bash
$ ./minke.sh rake app:build
```
The steps minke performs are:
1. Download Docker image or build image specified by the generator.
2. Start a new build container.
3. Fetch any dependencies.
4. Execute build command specified by the generator.

The output will look something like below.

```bash
# Loading installed generators
registered minke-generator-go
registered minke-generator-netmvc
registered minke-generator-swift
run fetch
## Update dependencies
/Users/nicj/Developer/crapola:/go/src/github.com/nicholasjackson/myservice
/Users/nicj/Developer/crapola/vendor:/packages/src
github.com/alexcesaro/statsd (download)
Fetching https://gopkg.in/alexcesaro/statsd.v2?go-get=1
Parsing meta tags from https://gopkg.in/alexcesaro/statsd.v2?go-get=1 (status code 200)
get "gopkg.in/alexcesaro/statsd.v2": found meta tag main.metaImport{Prefix:"gopkg.in/alexcesaro/statsd.v2", VCS:"git", RepoRoot:"https://gopkg.in/alexcesaro/statsd.v2"} at https://gopkg.in/alexcesaro/statsd.v2?go-get=1
gopkg.in/alexcesaro/statsd.v2 (download)
github.com/facebookgo/inject (download)
github.com/facebookgo/structtag (download)
github.com/facebookgo/ensure (download)
github.com/davecgh/go-spew (download)
github.com/facebookgo/stack (download)
github.com/facebookgo/subset (download)
github.com/asaskevich/govalidator (download)
github.com/gorilla/context (download)
github.com/gorilla/pat (download)
github.com/gorilla/mux (download)
github.com/stretchr/testify (download)
Downloaded packages
## Build application
["/bin/bash", "-c", "go build -a -installsuffix cgo -ldflags '-s' -o myservice"]
/Users/nicj/Developer/crapola:/go/src/github.com/nicholasjackson/myservice
/Users/nicj/Developer/crapola/vendor:/packages/src
```

The build task has a dependency on the fetch task so before we try to build anything we will fetch the dependencies (in this instance using go get) before executing the build.  
All of the code is run inside the docker container however most generators will use the physical disk of the Docker server to cache the output.  This speeds up the whole process and allows you to utilise any caching behavior of your CI environment if needed.

### Running the unit tests

```bash
$ ./minke.sh rake app:test
```
Running the unit tests is a similar process, before we run the tests we will build the application code and fetch any dependencies.   It all runs inside a container.

```bash
## Test application
/Users/nicj/Developer/crapola:/go/src/github.com/nicholasjackson/crapola
/Users/nicj/Developer/crapola/vendor:/packages/src
?   	github.com/nicholasjackson/crapola	        [no test files]
?   	github.com/nicholasjackson/crapola/global	[no test files]
ok  	github.com/nicholasjackson/crapola/handlers	0.013s
?   	github.com/nicholasjackson/crapola/logging	[no test files]
?   	github.com/nicholasjackson/crapola/mocks	[no test files]
```

### Build yourself an image
So we are going to run the cucumber tests against a Docker container and ultimately you want to run this on your server anyway so lets build an image which can be launched.

```bash
$ ./minke.sh rake app:build_image
```

That's all you need this will build and test your application code then copy the assets into the right location to be packaged up into a Docker image, all of the steps is configurable checkout the section on Config for more information.

### Functional tests
Having unit tests for your code covers you a little however there is a real benefit to having a good behavioral test suite which may even test the integration of your application with other dependencies such as database servers.
Minke uses Cucumber and Docker to facilitate this, it spins up a stack using Docker Compose and executes the Cucumber tests against it.  
Running the functional tests is as easy as...

```bash
$ ./minke rake app:cucumber
```

This will start the stack with Docker Compose using a standard format compose file which can be found in the **_build** folder, it loads any config that we may require for the service into Consul and then waits for the service to start before executing the Cucumber tests.  
And you have to do nothing other than write the test and setup the config all logic for service discovery and waiting for the service to start is handled for you.
All being well you should see some output like the stuff listed below.

```bash
# Loading installed generators
registered minke-generator-netmvc
## Running cucumber with tags
Creating apiipad_statsd_1
Creating apiipad_consul_1
Creating apiipad_registrator_1
Creating apiipad_apiipad_1
Server: http://192.168.99.100:32886/v1/status/leader passed health check, 1 checks to go...
Server: http://192.168.99.100:32886/v1/status/leader healthy
./consul_keys.yml
Updating key: /apiipad/Credentials/mysql/username with value: root
Updating key: /apiipad/Credentials/mysql/password with value: my-secret-pw
Updating key: /apiipad/Settings/environment with value: dev
Updating key: /apiipad/Settings/mysql/db_name with value: apiipad
Updating key: /apiipad/Settings/statsd/host with value: statsd
Updating key: /apiipad/Settings/statsd/port with value: 8125
Waiting for server http://192.168.99.100:32888/v1/health to start
Server: http://192.168.99.100:32888/v1/health passed health check, 3 checks to go...

...

@healthcheck
Feature: Health check
	In order to ensure quality
	As a user
	I want to be able to test functionality of my API

  Scenario: Health check returns ok                            # features/health.feature:10
    Given I send and accept JSON                               # cucumber-api-0.3/lib/cucumber-api/steps.rb:11
    When I send a GET request to the api endpoint "/v1/health" # features/steps/http.rb:1
    Then the response status should be "200"                   # cucumber-api-0.3/lib/cucumber-api/steps.rb:107
    And the JSON response should have key "status"             # cucumber-api-0.3/lib/cucumber-api/steps.rb:132

1 scenario (1 passed)
4 steps (4 passed)
0m0.026s
Stopping apiipad_apiipad_1 ... done
Stopping apiipad_registrator_1 ... done
Stopping apiipad_consul_1 ... done
Stopping apiipad_statsd_1 ... done
```

It really is that easy now all you need to do is push the image to the server and open a beer.  If you have managed to get this far I recommend checking out the documentation on the configuration files to see how you can customise and extend your build.