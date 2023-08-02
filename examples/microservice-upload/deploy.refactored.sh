#!/bin/bash
set -e

info ()  { echo "INFO   $*" >&2; }
error () { echo "ERROR  $*" >&2; }

print_usage() {
    echo "
Deploy a Cumulocity IoT microservice from a github release url

The script assumes the user has already configured a go-c8y-cli session or set the following environment variables:

* C8Y_HOST
* C8Y_USER
* C8Y_PASSWORD (or C8Y_TOKEN)

Usage:
    $0 [--skipSubscription]

Flags:
    --skipSubscription      Don't subscribe the application to the tenant

Examples:
    $0 https://api.github.com/repos/SoftwareAG/oee-simulators/releases/latest
    # Deploy the oee-simulators microservice and subscribe to it

    $0 https://api.github.com/repos/SoftwareAG/oee-simulators/releases/latest --skipSubscription
    # Deploy the oee-simulators microservice but don't subscribe to the application in the tenant


    docker run --rm --env-file <(env | grep '^C8Y_') -it deploy.sh https://api.github.com/repos/SoftwareAG/oee-simulators/releases/latest
    # Run the script from a docker container (importing the exposed environment variables from your current shell)

    docker run --rm -e C8Y_HOST='myhost' -e C8Y_PASSWORD='mypassword' -e C8Y_USERNAME='myuser' -it deploy.sh https://api.github.com/repos/SoftwareAG/oee-simulators/releases/latest
    # Run the script from a docker container (importing the exposed environment variables from your current shell)
"
}

print_exit_code() {
    info "List of exit code error:"
    info "2: failed to download microservice"
    info "3: failed to upload microservice"
    info "5: failed to get current tenant info"
}

check_current_tenant() {
    cur_tenant=$(c8y currenttenant get --select "name" -o csv ||:)
    if [ -z "$cur_tenant" ]; then
        error "Failed to get tenant info"
        exit 5
    fi
    info "Current tenant: $cur_tenant"
    export C8Y_TENANT="$cur_tenant"
}


download_microservice() {
    repo_url="$1"
    output_file=""
    if [ $# -gt 1 ]; then
        output_file="$2"
    fi
    gh_response=$(curl -s "$repo_url")

    # extract the download URL of the first asset
    asset_url=$(c8y util show --input "$gh_response" --select "assets.0.browser_download_url" -o csv)

    if [ -z "$output_file" ]; then
        output_file=$(basename "$asset_url")
    fi

    # Note: You might run into api throttling if don't provide a gh token
    # Prefer using an if block and don't check the exit code later (as that is done by the if block)
    # And generally a if block reads better than a if/else block
    info "Downloading assets $output_file..."
    if ! curl "$asset_url" -o "$output_file"; then
        error "Download $output_file failed"
        exit 2
    fi

    info "Download $output_file completed"

    # Return the output file (in case the user did not specify one)
    echo "$output_file"
    return
}

deploy_microservice() {
    file="$1"
    shift

    info "Deploying microservice [file=$file] to tenant $C8Y_TENANT..."

    if ! c8y microservices create --file "$file" --skipSubscription:$SUBSCRIBE "$@"; then
        error "Upload $file failed"
        exit 3
    fi

    info "Upload $file completed"
}

## Arguments handler
SUBSCRIBE="true"
REST_ARGS=()
REST_FLAGS=()
GITHUB_RELEASE_URL="https://api.github.com/repos/SoftwareAG/oee-simulators/releases/latest"

# Set sensible default for microservices because they tend to be larger, and take longer to upload
export C8Y_SETTINGS_DEFAULTS_TIMEOUT="600s"

# Parse command-line options
while [ $# -gt 0 ]; do
    case "$1" in
        --skipSubscription)
            SUBSCRIBE="false"
            ;;

        --timeout)
            export C8Y_SETTINGS_DEFAULTS_TIMEOUT="$2"
            shift
            ;;

        --help|-h)
            print_usage
            exit 0
            ;;

        --*|-*)
            REST_FLAGS+=("$1")
            ;;

        *)
            REST_ARGS+=("$1")
            ;;
    esac
    shift
done
set -- "${REST_ARGS[@]}" # Get all remain arguments which is not listed in the cases above

if [ $# -gt 0 ]; then
    GITHUB_RELEASE_URL="$1"
fi

## Main body starts here... ##
check_current_tenant
microservice_file=$(download_microservice "$GITHUB_RELEASE_URL")

# Allow the user to also pass any additional arguments to the deploy microservice
# call which are passed directly to c8y microservices create allow users to custom it as required
deploy_microservice "$microservice_file" "${REST_FLAGS[@]}"

exit 0
