# Overview

## Overview

### What is go-c8y-cli

* What about PSc8y? / I heard this was only for PowerShell?
* What does it work on?

### Uses

* CI/CD Pipeline
    * Automatic deployments
    * Deploy a microservice, hosted application
    * Tenant options

* Investigations

* Prototyping
    * Create devices and data

* Tenant management
    * Device management (firmware/software/configuration)
    * Cleanup

## Installation

* via package manager (Ubuntu/Debian, CentOS, Fedora)

* homebrew (MacOS)

* manually download the binary (no-frills)


## Main features



### Controlling the output data : Shaping the output data

* select and output
* Select limit the

### Output

* json or csv


### Views

* Default views
* Customize views


### Template language

* --data
* --template (jsonnet)

### Activity log

```sh
c8y activitylog list --dateFrom -30min --filter "path like *operation*" --filter "method eq POST" | jq
```

Check the response times of the create operations api calls

```sh
c8y activitylog list --dateFrom -30min --filter "path like *operation*" --filter "method eq POST" --select "ms:responseTimeMS" -o csvheader \
| datamash -H min 1 max 1 mean 1 --output-delimiter=, \
| column -t -s ,
```

### Piping

```
seq -f "device_%03g" 10 | c8y devices create
```

### Other tools

#### Play nice with other tooling

    ```sh
    curl -H "$C8Y_HEADER" "$C8Y_HOST/inventory/managedObjects"
    ```


## Advanced features

* --includeAll

* Get device totals
    * --withTotalPages --pageSize 1 `-t -p1`

* importing data


### Aliases

* Currently non tab completion


### Local caching

* Command responses can be cached locally (opt-in)

* Reduce number of scripts

* Dedupe when creating devices

    ```
    export 
    ```

    ```
    c8y cache delete
    c8y cache renew
    ```


## Running the demos

```sh
cd 2022-01-27
export C8Y_HOME="$( pwd )"
```

### Simulation

1. Create a set of devices


2. Create a generic software listener (c8y_Restart)

3. Manually create an operation

```
c8y operations list --device device_011 --status FAILED -p 1 --dateFrom -1h --revert --view copy_operation \
| c8y operations create --template "input.value" --device device_012
```

## Not covered today

* Workers
* 


## Roadmap

* Implementation of notifications 2.0 api
* Upload/Download progress bars
* Plugins?

* Output templates
* Extend pipe model to
