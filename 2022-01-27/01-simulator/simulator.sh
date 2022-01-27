#!/bin/bash

export C8Y_SETTINGS_DEFAULTS_FORCE=true

DEVICE_LIST="device.list"
TOTAL_DEVICES=100
WORKERS=50

setup () {
    c8y util repeat --input "device" --format "%s_%03s" "$TOTAL_DEVICES" |
        c8y agents create --workers 10 |
        c8y devices update --template "{c8y_SupportedOperations:['c8y_SoftwareList', 'c8y_Restart'], c8y_DeploymentGroup: {name: if input.index <= 10 then 'canary_10' else 'main' }}"
    c8y devices list --name "device_*" --pageSize 1000 --select id,name,type > "$DEVICE_LIST"
}

cleanup () {
    c8y devices list --includeAll --name "device_*" | c8y devices delete --workers 5 --delay 100ms --progress
}

#
# Measurement creation
#
start_measurements () {
    echo "Creating measurements"
    c8y util repeatfile --infinite "$DEVICE_LIST" \
    | c8y measurements create --template measurement.jsonnet --workers "$WORKERS" --delay 10000ms --select "source.id,**.value,**.unit" \
    | c8y util repeat --randomSkip 0.7 \
    | c8y events create --text "Example text" --type "c8y_RandomEvent" --workers "$WORKERS" --delay 5s
}

start_measurements_sine () {
    #
    # Use python to generate the signal and pass it to c8y to create
    # the measurement (with the timestamp)
    # Requires python "numpy". Install using "pip3 install numpy"
    #
    python3 waveform.py 1 \
    | c8y measurements create \
        --device "device_001" \
        --template "input.value" \
        --select "id,time,type,**.value"
}

#
# Operation handler simulators
#
start_operations_listener () {
    echo "Starting operations listener"
    c8y operations subscribe --duration 1h --actionTypes CREATE |
        c8y operations update --status EXECUTING --delayBefore 750ms --workers $WORKERS |
        c8y operations update --status SUCCESSFUL --delayBefore 5s --workers $WORKERS
}

create_restart_operation () {
    c8y operations create \
        --description "Restart device" \
        --template "{c8y_Restart: {}}" < "$DEVICE_LIST"
}


start_software_listener_realtime () {
    local threshold="${1:-50}"
    #
    # Note: use line-buffered option in grep otherwise the pipeline will be buffered
    #
    echo "Starting software operations listener (realtime)"
        # c8y devices update --template "{c8y_SoftwareList: [x for x in input.value.c8y_SoftwareList if x.action == 'install']}" --delayBefore 5s --workers $WORKERS |

    c8y operations subscribe --duration 1h --actionTypes CREATE |
        grep --line-buffered "c8y_SoftwareList" |
        c8y operations update --status EXECUTING --delay 750ms --workers 10 |
        c8y devices update --template "{c8y_SoftwareList: input.value.c8y_SoftwareList}" --delayBefore 5s --workers $WORKERS |
        c8y operations list --fragmentType "c8y_SoftwareList" --pageSize 1 --status EXECUTING --workers $WORKERS |
        c8y operations update --template "random.operation.error.jsonnet" --templateVars "threshold=$threshold" --workers 10
        # c8y operations update --status SUCCESSFUL --workers 10
}

start_software_listener_poll () {
    local sleep_interval=${1:-"5s"}
    echo "Starting software operations listener (poll)"
    while true;
    do
        c8y operations list --fragmentType c8y_SoftwareList --pageSize 100 --delay 2s --status PENDING |
            grep --line-buffered "c8y_SoftwareList" |
            c8y operations update --status EXECUTING --workers $WORKERS |
            c8y devices update --template "{c8y_SoftwareList: input.value.c8y_SoftwareList}" --delayBefore 5s |
            c8y operations list --fragmentType "c8y_SoftwareList" --pageSize 1 --status EXECUTING |
            c8y operations update --status SUCCESSFUL --workers $WORKERS
        
        sleep "$sleep_interval"
    done
}

create_software_operation () {
    local suffix
    suffix="${1:-}"
    c8y operations create \
        --description "Set software list" \
        --template "./software.operation.jsonnet" \
        --templateVars "suffix=$suffix" < "$DEVICE_LIST" 
}

cleanup_operations () {
    echo "Cleaning up operations"
    c8y operations list --status EXECUTING --includeAll | c8y operations update --status SUCCESSFUL
    c8y operations list --status PENDING --includeAll | c8y operations update --status SUCCESSFUL
}

show_stats () {
    echo "c8y activitylog list --dateFrom -1h --select path,responseTimeMS -o csvheader --filter \"method like POST\" | tr ',' '\t' | datamash groupby 1 -R 2 -H min 2 max 2 mean 2 --sort"
    echo ""

    c8y activitylog list --dateFrom -1h --select path,responseTimeMS -o csvheader --filter "method like POST" | tr "," "\t" | datamash groupby 1 -R 2 -H min 2 max 2 mean 2 --sort
}