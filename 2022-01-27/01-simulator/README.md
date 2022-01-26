
# Device simulations

## Configure some default settings

```
c8y settings update cache.methods GET\ PUT\ POST\ DELETE
c8y settings update defaults.cacheTTL 600h
c8y settings update logger.hideSensitive true
```

## Create a set of devices

```sh
c8y util repeat --input "device" --format "%s_%03s" 10 | c8y devices create -f --cache --delay 5s
```

* use local caching to prevent creating the same device twice (only works if the body is the same)

## Save the devices to file, as this is going to provide my device inputs 

```
c8y devices list --name "device_*" --pageSize 200 --cache
```

Or save the list to file

```sh
c8y devices list --name "device_*" --pageSize 200 --cache --select id,name,type > device.list
```


## Generate a list of measurements

```sh
c8y util repeatfile device.list --infinite | c8y measurements create --template measurement.jsonnet -f --delay 2s --workers 10 --delay 5s
```


```

start_worker_1 () {
    echo "Starting worker 1"
    c8y util repeatfile device.list --infinite \
    | c8y measurements create --template measurement.jsonnet -f --delay 2s --workers 10 --delay 5s
}

```

echo -n "" > myfile


## Create new software

```
c8y software create --name vim | c8y software versions create --version 1.0.1
```

## Retry a failed operation

```
c8y operations list --device device_011 --status FAILED -p 1 --dateFrom -1h --revert --view copy_operation \
| c8y operations create --template "input.value" --device device_012
```
