#!/bin/bash

measurement_pipe=/tmp/measurement_stream
DEVICE_LIST="device.list"
export C8Y_SETTINGS_DEFAULTS_FORCE=true
TOTAL_DEVICES=10
WORKERS=10

if [[ ! -p "$measurement_pipe" ]]; then
    mkfifo "$measurement_pipe"
fi

setup () {
    c8y util repeat --input "device" --format "%s_%03s" "$TOTAL_DEVICES" |
        c8y agents create --workers 10 |
        c8y devices update --template "{c8y_SupportedOperations:['c8y_SoftwareList', 'c8y_Restart']}"
    c8y devices list --name "device_*" --pageSize 1000 --select id,name,type > "$DEVICE_LIST"
}

cleanup () {
    c8y devices list --includeAll --name "device_*" --owner "demo01" | c8y devices delete --workers 5 --delay 100ms --progress
}

run_sim () {
    i=1
    while true
    do
        echo "Run: $((i++))"
        cat "$DEVICE_LIST" | tee -a "$measurement_pipe"
        sleep 10s
    done
}

start_worker_1 () {
    echo "Starting worker 1"
    tail -f "$measurement_pipe" | c8y measurements create --template measurement.jsonnet --workers $WORKERS --delay 1000ms --select "source.id,**.value,**.unit"
}

start_operations_worker () {
    echo "Starting c8y_Restart operations worker"
    c8y operations subscribe --duration 1h --actionTypes CREATE |
        grep --line-buffered "c8y_Restart" |
        c8y operations update --status EXECUTING --delayBefore 750ms --workers $WORKERS |
        c8y operations update --status SUCCESSFUL --delayBefore 5s --workers $WORKERS
}

create_restart_operation () {
    tail -f "$measurement_pipe" |
        head -$TOTAL_DEVICES |
        c8y operations create --description "Restart device" --template "{c8y_Restart: {}}"
}

start_software_listener () {
    #
    # Note: use line-buffered option in grep otherwise the pipeline will be buffered
    #
    echo "Starting software operations worker"

    c8y operations subscribe --duration 1h --actionTypes CREATE |
        grep --line-buffered "c8y_SoftwareList" |
        c8y operations update --status EXECUTING --delay 750ms --workers 10 |
        c8y devices update --template "{c8y_SoftwareList: input.value.c8y_SoftwareList}" --delayBefore 5s --workers $WORKERS |
        c8y operations list --fragmentType "c8y_SoftwareList" --pageSize 1 --status EXECUTING --workers $WORKERS |
        c8y operations update --status SUCCESSFUL --workers 10 --workers 10
}

start_software_handler () {
    echo "Starting software operations worker"
    while true;
    do
        c8y operations list --fragmentType c8y_SoftwareList --pageSize 100 --delay 2s --status PENDING |
            grep --line-buffered "c8y_SoftwareList" |
            c8y operations update --status EXECUTING --workers $WORKERS |
            c8y devices update --template "{c8y_SoftwareList: input.value.c8y_SoftwareList}" --delayBefore 5s |
            c8y operations list --fragmentType "c8y_SoftwareList" --pageSize 1 --status EXECUTING |
            c8y operations update --status SUCCESSFUL --workers $WORKERS
        
        sleep 5s
    done
}

create_software_operation () {
    local suffix
    suffix="${1:-}"
    tail -f "$measurement_pipe" |
        head -$TOTAL_DEVICES |
        c8y operations create --description "Set software list" --template "./software.operation.jsonnet" --templateVars "suffix=$suffix"
}

cleanup_operations () {
    echo "Cleaning up operations"
    c8y operations list --status EXECUTING --includeAll | c8y operations update --status SUCCESSFUL
    c8y operations list --status PENDING --includeAll | c8y operations update --status SUCCESSFUL
}
