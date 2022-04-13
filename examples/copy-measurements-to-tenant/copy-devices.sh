#!/bin/bash
####################################################################################
# Copy measurements from a source tenant to a destination tenant processing one
# device at a time
#
# Author: Reuben Miller
# Date: 2022-04-13
####################################################################################

SESSION_DST=
WORKERS=5
WORKER_DELAY="100ms"
DATE_FROM="-365d"
DATE_TO="0d"
DEVICES=()
TIMEOUT="15m"
COPY_TYPES=measurements,events,alarms
DEVICE_QUERY=""

show_usage () {
    echo ""
    echo "Usage:"
    echo "    $0 --destination <session_config> [--workers <number>] [--delay <duration>] [--dateFrom <date|relative>] [--dateTo <date|relative>] [--types <measurements,events,alarms>] --device-query <query>"
    echo ""
    echo "Example 1: Copy all measurements, events and alarms from all devices, and don't prompt for confirmation"
    echo ""
    echo "    $0 --destination targetTenantConfig.json --type measurements,events,alarms --force"
    echo ""
    echo ""
    echo "Example 2: Copy measurements from all devices (with c8y_IsDevice fragment), but only copy measurements between dates 100 days ago to 7 days ago"
    echo ""
    echo "    $0 --destination targetTenantConfig.json --dateFrom -100d --dateTo -7d --type measurements --device-query \"has(c8y_IsDevice)\""
    echo ""
    echo ""
    echo "Arguments:"
    echo ""
    echo "  --device-query <string> : Device query to select which devices should be copied"
    echo "  --workers <int> : Number of concurrent workers to create the measurements"
    echo "  --destination <string> : Session destination where the measurements will be copied to"
    echo "  --dateFrom <date|relative_date> : Only include measurements from a specific date"
    echo "  --dateTo <date|relative_date> : Only include measurements to a specific date"
    echo "  --delay <interval> : Delay between after each concurrent worker. This is used to rate limit the workers (to protect the tenant)"
    echo "  --types <csv_list> : CSV list of c8y data types, i.e. measurements,events,alarms"
    echo "  --query <string> : Inventory managed object query"
    echo "  --force|-f : Don't prompt for confirmation"
    echo ""
}

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
    
    --dateFrom)
      DATE_FROM="$2"
      shift
      shift
      ;;
    
    --dateTo)
      DATE_TO="$2"
      shift
      shift
      ;;
    
    --delay)
      WORKER_DELAY="$2"
      shift
      shift
      ;;
    
    --types)
      COPY_TYPES="$2"
      shift
      shift
      ;;
    
    --device-query)
      DEVICE_QUERY="$2"
      shift
      shift
      ;;
    
    -f|--force)
      export C8Y_SETTINGS_DEFAULTS_FORCE="true"
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
  esac
done

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
    device_id=$( echo "$device" | c8y util show --select id -o csv | xargs )
    device_name=$( echo "$device" | c8y util show --select name -o csv | xargs )
    echo -e "\nCopying $COPY_TYPES from device [id=${device_id}, name=${device_name}]"

    #
    # Check if the managed object exists already and if not create it by copying the managed object (except for the id, and lastUpdated fields)
    # Store the destination device id for later usage.
    #
    dst_device_id="$( c8y inventory find -n --session "$SESSION_DST" --query "name eq '$device_name'" --orderBy name --pageSize 2 --select id -o csv )"
    dst_match_count="$(echo "$dst_device_id" | grep "^[0-9]\+$" | wc -l | xargs)"

    case "$dst_match_count" in
      0)
        echo "Creating device [name=$device_name] in destination tenant"
        dst_device_id=$( c8y inventory create -n --session "$SESSION_DST" --template "$device + {id:: '', lastUpdated:: ''}" --select id -o csv --force )
        ;;
      1)
        echo "Updating device [name=$device_name] in destination tenant"
        dst_device_id=$( c8y inventory update -n --session "$SESSION_DST" --id "$dst_device_id" --template "$device + {id:: '', lastUpdated:: ''}" --select id -o csv --force)
        ;;
      *)
        echo "Too many devices found matching [total=$dst_match_count, name=$device_name] in destination tenant. Skipping copy action as it is not sure which is the correct destination device"
        continue
        ;;
    esac

    # Copy measurements from source tenant to destination tenant
    if [[ "$COPY_TYPES" =~ "measurements" ]]; then
      # Get the total amount of items in source tenant (for a sanity check)
      total=$( c8y measurements list -n --device "$device_id" --cache --dateFrom "$DATE_FROM" --dateTo "$DATE_TO" --pageSize 1 --withTotalPages --select statistics.totalPages -o csv )

      echo "$device" \
      | c8y measurements list --includeAll --dateFrom "$DATE_FROM" --dateTo "$DATE_TO" --cache --select '!id,**' --timeout "$TIMEOUT" \
      | c8y measurements create \
          --device "$dst_device_id" \
          --template "input.value" \
          --session "$SESSION_DST" \
          --workers "$WORKERS" \
          --delay "$WORKER_DELAY" \
          --progress \
          --confirmText "Do you want to copy $total measurements to this device" \
          --timeout "$TIMEOUT" \
          --abortOnErrors 1000000 \
          --cache
    fi

    # Copy events from source tenant to destination tenant
    if [[ "$COPY_TYPES" =~ "events" ]]; then
      # Get the total amount of items in source tenant (for a sanity check)
      total=$( c8y events list -n --device "$device_id" --cache --dateFrom "$DATE_FROM" --dateTo "$DATE_TO" --pageSize 1 --withTotalPages --select statistics.totalPages -o csv )

      echo "$device" \
      | c8y events list --includeAll --dateFrom "$DATE_FROM" --dateTo "$DATE_TO" --cache --select '!id,**' --timeout "$TIMEOUT" \
      | c8y events create \
          --device "$dst_device_id" \
          --template "input.value" \
          --session "$SESSION_DST" \
          --workers "$WORKERS" \
          --delay "$WORKER_DELAY" \
          --progress \
          --confirmText "Do you want to copy $total events to this device" \
          --timeout "$TIMEOUT" \
          --abortOnErrors 1000000 \
          --cache
    fi

    # Copy alarms from source tenant to destination tenant
    if [[ "$COPY_TYPES" =~ "alarms" ]]; then
      # Get the total amount of items in source tenant (for a sanity check)
      alarms_total=$( c8y alarms list -n --device "$device_id" --cache --dateFrom "$DATE_FROM" --dateTo "$DATE_TO" --pageSize 1 --withTotalPages --select statistics.totalPages -o csv )

      echo "$device" \
      | c8y alarms list --includeAll --dateFrom "$DATE_FROM" --dateTo "$DATE_TO" --cache --select '!id,**' --timeout "$TIMEOUT" \
      | c8y alarms create \
          --device "$dst_device_id" \
          --template "input.value" \
          --session "$SESSION_DST" \
          --workers "$WORKERS" \
          --delay "$WORKER_DELAY" \
          --progress \
          --confirmText "Do you want to copy $total alarms to this device" \
          --timeout "$TIMEOUT" \
          --abortOnErrors 1000000 \
          --cache
    fi

# Below controls which devices you want to move the measurements from. You can customize the query to anything you want
# done < <( printf "%s\n" "${DEVICES[@]}" | c8y devices get )
done < <( c8y devices list --includeAll --query "$DEVICE_QUERY" )
