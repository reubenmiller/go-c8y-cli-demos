#!/bin/bash

set -euo pipefail

if ! declare -p GITHUB_RUN_ID 2>/dev/null; then
    GITHUB_RUN_ID=0
fi

if ! declare -p GITHUB_RUN_NUMBER 2>/dev/null; then
    GITHUB_RUN_NUMBER=0
fi

if ! declare -p GITHUB_REF_NAME 2>/dev/null; then
    GITHUB_REF_NAME=0
fi

if ! declare -p GITHUB_SHA 2>/dev/null; then
    GITHUB_SHA=0
fi


echo "Removing previous configuration files"
c8y configuration list --query "configurationType eq 'DEVICE_AGENT' and has(cicd_build)" \
| c8y configuration delete

echo "Uploading configuration files"
for file in *agent*.ini; do
    echo -e "c8y_Linux\nc8y_MacOS\nc8y_Windows" |
        c8y configuration create --name "${file%.*}" \
            --configurationType "DEVICE_AGENT" \
            --file "$file" \
            --template "{description: 'Agent config (branch: $GITHUB_REF_NAME, run: $GITHUB_RUN_NUMBER)', cicd_build: {branch: '$GITHUB_REF_NAME', sha: '$GITHUB_SHA', runId: '$GITHUB_RUN_ID', runNumber: '$GITHUB_RUN_NUMBER'}}"
done
