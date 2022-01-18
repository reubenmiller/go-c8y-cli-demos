#!/bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
pushd "$SCRIPT_DIR" || exit 1

echo "Deploying an web application"
find . -type d -name "*web*" -exec c8y applications createHostedApplication --file "{}/" \;

echo "Cleanup: Keeping last 3 deployed applications"
echo "mywebapp" \
    | c8y applications listApplicationBinaries -p 100 \
    | head -n -3 \
    | c8y applications deleteApplicationBinary --application mywebapp
