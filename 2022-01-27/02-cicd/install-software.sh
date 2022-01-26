#!/bin/bash

# bash options to fail fast
set -euo pipefail

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
pushd "$SCRIPT_DIR" || exit 1

install_software () {
    local group_name="$1"
    local name="$2"
    local version="$3"

    echo "Install software: name=$name, version=$version, deployment_group=$group_name"
    c8y devices list -n --includeAll --query "c8y_DeploymentGroup.name eq '$group_name'" \
    | c8y software versions install --software "$name" --version "$version"
}

#
# Main
#
install_software "$1" "$2" "$3"
