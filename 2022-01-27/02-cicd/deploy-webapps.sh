#!/bin/bash
keep_last=5

if [ "$#" -gt 0 ]; then
    keep_last="$1"
fi

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
pushd "$SCRIPT_DIR" || exit 1

deploy_app () {
    local name="$1"

    echo "[name=$name] Deploying an web application (keeping only last 3 deployments)"
    c8y applications createHostedApplication -n --file "$name/" \
        | c8y applications listApplicationBinaries -p 100 \
        | head -n "-$keep_last" \
        | c8y applications deleteApplicationBinary --application "$name"
}

#
# Main
#
deploy_app "mywebapp"
