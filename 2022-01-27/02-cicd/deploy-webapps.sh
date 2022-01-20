#!/bin/bash

# bash options to fail fast
set -euo pipefail

keep_last=5

if [ "$#" -gt 0 ]; then
    keep_last="$1"
fi

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
pushd "$SCRIPT_DIR" || exit 1

deploy_app () {
    local name="$1"

    echo "[name=$name] Deploying an web application (keeping only last 3 deployments)"
    c8y applications createHostedApplication --file "$name/" \
        | c8y applications listApplicationBinaries -p 100 \
        | head -n "-$keep_last" \
        | c8y applications deleteApplicationBinary --application "$name"
    
    #
    # Add tenant options
    deployed_date="$(date --iso-8601=seconds)"
    c8y tenantoptions create --category "$name" --key "deployed_on" --value "$deployed_date"
}

#
# Main
#
deploy_app "mywebapp"
