#!/bin/bash
####################################################################################
# Copy measurements from a source tenant to a destination tenant processing one
# device at a time
####################################################################################

SESSION_DST=
WORKERS=5
WORKER_DELAY="100ms"

show_usage () {
    echo ""
    echo "Usage:"
    echo "    $0 --destination <session_config> [--workers <number>] [--delay <duration>]"
    echo ""
    echo "Example"
    echo ""
    echo "    $0 --destination targetTenantConfig.json"
    echo ""
}

POSITIONAL_ARGS=()

while [[ $# -gt 0 ]]; do
  case $1 in
    --destination)
      SESSION_DST="$2"
      shift
      shift
      ;;
    
    --workers)
      WORKERS="$2"
      shift
      shift
      ;;
    
    --delay)
      WORKER_DELAY="$2"
      shift
      shift
      ;;
    
    -h|--help)
      show_usage
      exit 0
      ;;

    -*|--*)
      echo "Unknown option $1"
      exit 1
      ;;

    *)
      POSITIONAL_ARGS+=("$1")
      shift
      ;;
  esac
done

set -- "${POSITIONAL_ARGS[@]}" # restore positional parameters


if [[ -z "$SESSION_DST" ]]; then
    echo "Missing required parameter '--destination <session_config>'"
    show_usage
    exit 1
fi


#
# Settings to control local client cache, so that we can reduce load on the servers.
# If the script is cancelled, then the same commands should not be repeated as it will get the
# response from the local disk cache rather than from the server.
#
export C8Y_SETTINGS_CACHE_METHODS="GET PUT POST DELETE"
export C8Y_SETTINGS_CACHE_TTL="7d"


TENANT_SRC="$(c8y sessions get --select host,tenant -o csv)"
TENANT_DST="$(c8y sessions get --select host,tenant -o csv --session "$SESSION_DST" )"

#
# Check that the user has not accidentally set the same tenant as source and destination
if [[ "$TENANT_SRC" == "$TENANT_DST" ]]; then
  echo "Source and destination tenant are the same!!! Aborting"
  exit 2
fi

echo "Current (source) tenant: $(c8y sessions get --select host,tenant -o json -c)"

#
# Loop through a list of devices, moving the measurements from the current tenant to the destination tenant
#
while read -r device ; do
    device_id=$( echo "$device" | c8y util show --select id -o csv )
    device_name=$( echo "$device" | c8y util show --select name -o csv )
    echo "Copying measurements from device [id=${device_id}, name=${device_name}]"

    #
    # Check if the device exists already nad if not create it by copying the managed object (except for the id, and lastUpdated fields)
    # Store the destination device id for later usage.
    #
    dst_device_id=$(
        c8y devices get -n --id "$device_name" --session "$SESSION_DST" --silentStatusCodes 404 --select id -o csv || {
            echo "Creating device [name=$device_name] in destination tenant"
            c8y devices create -n --session "$SESSION_DST" --template "$device + {id:: '', lastUpdated:: ''}" --select id -o csv
        }
    )

    # Get the total amount of measurements in source tenant (for a sanity check)
    total_measurements=$( c8y measurements list -n --device "$device_id" --cache --pageSize 1 --withTotalPages --select statistics.totalPages -o csv )
    
    # Copy measurements from source tenant to destination tenant
    echo "$device" \
    | c8y measurements list --includeAll --cache --select '!id,**' \
    | c8y measurements create \
        --device "$dst_device_id" \
        --template "input.value" \
        --session "$SESSION_DST" \
        --confirm \
        --workers "$WORKERS" \
        --delay "$WORKER_DELAY" \
        --progress \
        --confirmText "Do you want to copy $total_measurements measurements to this device" \
        --cache

# Below controls which devices you want to move the measurements from. You can customize the query to anything you want
done < <( c8y devices list --pageSize 100 )
