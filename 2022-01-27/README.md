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

* --data (shorthandle json)
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

### Other tooling

#### Play nice with other tooling

```sh
curl -H "$C8Y_HEADER" "$C8Y_HOST/inventory/managedObjects"
```



### Aliases

* Create command shortcuts for common commands (though aliases do not have tab completion)


### Local caching

* Command responses can be cached locally (opt-in)

* Reduce number of scripts

* Dedupe when creating devices


## Running the demos

```sh
cd 2022-01-27
export C8Y_HOME="$( pwd )"
```

### Simulation

1. Create a set of devices

    ```sh
    source 01-simulator/simulator.sh

    # create the devices
    setup
    ```

2. Create a generic software listener (c8y_Restart)

    ```sh
    start_operations_listener
    ```

3. Manually create an operation

    ```sh
    create_software_operation
    ```

4. Copy an existing operation to re-run it on the same device or another one

    ```
    c8y operations list --device device_001 --status FAILED -p 1 --dateFrom -1h --revert --view copy_operation \
    | c8y operations create --template "input.value" --device device_011 \
    | c8y operations wait
    ```


### CI/CD Pipeline

1. Setup the simulated operation listener

    ```sh
    source 01-simulator/simulator.sh

    # create the devices
    setup

    # start listener
    start_software_listener_realtime
    ```

2. Trigger workflow manually

    ```sh
    gh workflow run deploy-example02 -f keep_last=3 -f deploy_ms=false
    ```

3. Check the progress of the workflow

    ```sh
    gh run list --workflow=deploy-example02.yml --limit 5
    ```

4. Check the output of the workflow and the bulk operation overview in Cumulocity Device Manager application



## Road map

The following is a hint at some of the features on the road map. But if you other suggestions let me know.

* Implementation of notifications 2.0 api
* Upload/Download progress bars
* Plugins?
* Output templates
* Piping model improvements (option to set all flags via piped input)
