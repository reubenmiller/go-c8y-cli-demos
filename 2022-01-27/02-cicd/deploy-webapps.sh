#!/bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
pushd "$SCRIPT_DIR" || exit 1

deploy_app () {
    local name="$1"

    echo "[name=$name] Deploying an web application"
    # find . -type d -name "*web*" -exec c8y applications createHostedApplication --file "{}/" \;
    c8y applications createHostedApplication -n --file "$name/"

    echo "[name=$name] Cleanup: Keeping last 3 deployed applications"
    echo "$name" \
        | c8y applications listApplicationBinaries -p 100 \
        | head -n -3 \
        | c8y applications deleteApplicationBinary --application "$name"
}

#
# Main
#
deploy_app "mywebapp"
