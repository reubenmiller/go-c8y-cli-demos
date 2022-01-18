#!/bin/bash

echo "Deploying an web application"
find . -type d -name "*web*" -exec c8y applications createHostedApplication --file "{}/" \;

echo "Cleanup: Keeping last 3 deployed applications"
c8y applications listApplicationBinaries --id mywebapp -p 100 \
    | head -n -3 \
    | c8y applications deleteApplicationBinary --application mywebapp
