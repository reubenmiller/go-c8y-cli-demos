#!/bin/bash

# bash options to fail fast
set -euo pipefail

if ! declare -p GITHUB_RUN_NUMBER 2>/dev/null; then
    GITHUB_RUN_NUMBER=0
fi


SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
pushd "$SCRIPT_DIR" || exit 1

log() { echo "$@" 1>&2; }


monitor_bulk_operation () {
    local bulk_operation="$1"
    local timeout_limit
    timeout_limit=$(( $(date +%s) + 300 ))

    while true; do
        #
        # Check current status of bulk operation
        #
        now=$(date +%s)
        current_bulk_op=$( echo "$bulk_operation" | c8y bulkoperations get --select generalStatus,progress.all,progress.successful -o csv )
        status=$( echo "$current_bulk_op" | cut -d, -f1 )
        all=$( echo "$current_bulk_op" | cut -d, -f2 )
        successful=$( echo "$current_bulk_op" | cut -d, -f3 )
        success_rate=$(( successful * 100 / all ))

        log "Current status: status=$status, total=$all, successful=$successful (success_rate=$success_rate)"

        # Was it succesful
        if [[ "$status" == "SUCCESSFUL" ]]; then
            log "Bulk operation was SUCCESSFUL, can proceed with other deployments"
            echo "$success_rate"
            return 0
        fi

        if [[ "$status" == "FAILED" ]]; then
            log "Bulk operation was SUCCESSFUL, can proceed with other deployments"
            echo "$success_rate"
            return 0
        fi

        if [[ "$now" -gt "$timeout_limit" ]]; then
            log "Bulk operaiton did not complete in the expected time. Please check the deployment for details"
            echo "$success_rate"
            return 1
        fi

        sleep 1s
    done
}

check_operation_failure_reasons () {
    local bulk_operation_id="$1"

    log "--------------------------------------------------"
    log "          Analysing failure reasons"
    log "--------------------------------------------------"
    echo "$bulk_operation_id" | c8y bulkoperations listOperations --status FAILED --includeAll --select failureReason --output csv \
    | sort \
    | uniq -c
}

install_software () {
    local group_name="$1"
    local name="$2"
    local version="$3"

    local bulk_operation_template="
    {
        note: 'This was deployed from the CI/CD runner: run=$GITHUB_RUN_NUMBER',
        operationPrototype: {
            description: 'CICD [id=$GITHUB_RUN_NUMBER, group=$group_name]: Update software to: $name (version $version)',
            c8y_SoftwareList: [
                {name: '$name', version: '$version'}
            ]
        }
    }
    "

    log "Creating bulk operation"

    bulk_operation=$(
        c8y smartgroups create \
            --name "CICD deployment [id=$GITHUB_RUN_NUMBER, group=$group_name]" \
            --invisible --query "c8y_DeploymentGroup.name eq '$group_name'" \
        | c8y bulkoperations create \
            --creationRampSec "1" \
            --startDate "5s" \
            --template "$bulk_operation_template"
    )

    log "Bulk Operation: $bulk_operation"

    # Monitor bulk operation
    success_rate=$( monitor_bulk_operation "$bulk_operation" )
    if [[ "$success_rate" -lt 90 ]]; then
        log "Bulk operation success rate is too low to continue: expected>=$success_rate, got=$success_rate"

        check_operation_failure_reasons "$bulk_operation"

        exit 1
    fi
}

#
# Main
#

LATEST_VERSION=$( c8y software versions list -n --software python3-c8ylp --includeAll --select "*.version" -o csv | sort -Vr | head -1 )
install_software "$1" "$2" "$LATEST_VERSION"
