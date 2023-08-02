#!/bin/bash

## Functions first... ##

function print_usage() { 
  echo "At least four command line arguments / environment variables must be inputted"
  echo ""
  echo "Command line: "
  echo "docker run <HOSTNAME> <USERNAME> <PASSWORD> <CI>"
  echo ""
  echo "Environment variables:"
  echo "docker run"
  echo ""
  echo "with following arguments (names = environment variables): "
  echo "HOSTNAME = the url to access tenant"
  echo "USERNAME = an existing user of the tenant"
  echo "PASSWORD = the password to access tenant"
  echo "CI = set to 'true' if current system is used for CI/CD, false otherwise"
  exit 1
}

function print_exit_code() {
    echo "List of exit code error:"
    echo "1: missing argument(s) / environment variable(s)"
    echo "2: failed to download microservice"
    echo "3: failed to upload microservice"
    echo "4: failed to subscribe tenant to microservice"
    echo "5: failed to get current tenant info"
}

add_params_to_command() {
  local base_command="$1"
  local params=("${@:2}")

  if [ ${#params[@]} -gt 0 ]; then
    for param in "${params[@]}"; do
      base_command+=" $param"
    done
  fi

  echo "$base_command"
}

check_current_tenant() {
  base_command='c8y currenttenant get --select "name"'
  final_command=$(add_params_to_command "$base_command" "${PARAMS[@]}")

  response=$(eval "$final_command")

  if [[ -z "$response" ]]; then
    echo "Error: Failed to get tenant info."
    exit 5
  fi
  export C8Y_TENANT=$(echo "$response" | jq -r '.name')
}

function check_environment_variables() {
    if [[ -z "$HOST_NAME" && -z "$1" ]]; then
      echo "Error: Missing HOSTNAME argument."
      print_usage
    fi

    if [[ -z "$USERNAME" && -z "$2" ]]; then
      echo "Error: Missing USERNAME argument."
      print_usage
    fi

    if [[ -z "$PASSWORD" && -z "$3" ]]; then
      echo "Error: Missing PASSWORD argument."
      print_usage
    fi

    if [[ -z "$C8Y_CI" && -z "$4" ]]; then
      echo "Error: Missing CI argument."
      print_usage
    fi
}

function export_environment_variables() {
    export C8Y_HOST="${1-$HOST_NAME}"
    export C8Y_USERNAME="${2-$USERNAME}"
    export C8Y_PASSWORD="${3-$PASSWORD}"
    export CI="${4-$C8Y_CI}"

    echo "C8Y_HOST: $C8Y_HOST"
    echo "C8Y_USERNAME: $C8Y_USERNAME"
    echo "CI: $CI"
}

function download_microservice() {
  repo_url="$1"
  asset_url=$(curl -s "$repo_url" | jq -r '.assets[0].browser_download_url') # extract the download URL of the first asset
  asset_name=$(basename "$asset_url")

  echo "Downloading assets $asset_name..."
  wget "$asset_url" -O "$asset_name"
  exit_code=$?
  if [[ $exit_code -eq 0 ]]; then
    echo "Download $asset_name completed"
    return 0
  else
    echo "Download $asset_name failed"
    exit 2
  fi
}

subscribe_microservice() {
  microservice_id="$1"
  echo "Subscribing microservice $microservice_id to tenant $C8Y_TENANT..."

  base_command="c8y bpl microservice subscribe --id $microservice_id --tenant $C8Y_TENANT --ignoreAlreadyDone"
  final_command=$(add_params_to_command "$base_command" "${PARAMS[@]}")
  response=$(eval "$final_command")
  exit_code=$?

  if [[ $exit_code -eq 0 ]]; then
    echo "Subscribe to microservice $microservice_id completed"
    return 0
  else
    echo "Subscribe to microservice $microservice_id failed"
    exit 4
  fi
}

function upload_microservice() {
  zip_file="$1"
  microservice_name="${zip_file%.zip}"
  base_command="c8y microservices create --file $zip_file"
  if [[ "$subscribe" == false ]]; then
    base_command+=" --skipSubscription"
  fi
  final_command=$(add_params_to_command "$base_command" "${PARAMS[@]}")

  echo "Uploading $zip_file..."
  response=$(eval "$final_command")
  exit_code=$?

  if [[ $exit_code -eq 0 ]]; then
    echo "Upload $zip_file completed"
    return 0
  elif [[ $exit_code -eq 100 ]]; then
    echo "Upload $zip_file completed"
    subscribe_microservice "$microservice_name"
    return 0
  else
    echo "Upload $zip_file failed"
    exit 3
  fi

}

## Arguments handler
subscribe=true
REST_ARGS=()
PARAMS=()
# Parse command-line options
while [[ $# -gt 0 ]]; do
  case "$1" in
    # BUG: Missing '--'' prefix, otherwise it expects the user to call: deploy.sh skipSubscription which reads a bit strange
    skipSubscription)
      subscribe=false
      ;;
    --timeout|-timeout)
      if [[ $# -gt 1 ]]; then
        # BUG: This will fail if the user calls with: -timeout 60s (as -timeout is not supported by go-c8y-cli)
        # Don't both with the single dash prefixes as that is generally reserved for options like "-t" etc.
        PARAMS+=("$1 $2")
        shift
      else
        echo "Option $1 requires an argument." >&2
        exit 1
      fi
      ;;
    *)
      REST_ARGS+=("$1")
      ;;
  esac
  shift
done
set -- "${REST_ARGS[@]}" # Get all remain arguments which is not listed in the cases above

## Main body starts here... ##

check_environment_variables "$@"
export_environment_variables "$@"
check_current_tenant


download_microservice "https://api.github.com/repos/SoftwareAG/oee-simulators/releases/latest"
upload_microservice "oee-simulators.zip"

exit 0
