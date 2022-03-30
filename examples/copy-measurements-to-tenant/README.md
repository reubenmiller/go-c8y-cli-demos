# Copy measurements from source tenant to a destination tenant

## What does it do?

The copy-measurements.sh script copies all measurements from a list of devices from the current tenant (session) to a given destination tenant.

The script first gets a list of devices (using an inventory query), then iterates of each of those devices and does the following actions

1. Check if a device with the name exists in the target tenant, if not it creates it by copying the device managed object from the source tenant
2. Counts how many measurements are related to the current device in the source tenant
3. Iterates through all of the current device's measurements and create them on the device in the destination tenant

### Assumptions

* The device ".name" property is unique in the tenant and can be used to identify the device

## Warnings

Please read the warnings before using this script.

* Creating large number of measurements can put significant load on a tenant. Try to limit the amount of measurements that need copying to a minimum by adding additional dateFrom/dateTo filtering on the `c8y measurements list` commands.
* Adjust the amount of workers and delay to something that is sustainable to the target tenant

## Usage

1. Create two go-c8y-cli sessions, one for the source tenant and one for the destination tenant. Make note of the file locations.

    You can find out the session file path by using the following commands

    ```sh
    # set session (via interactive menu)
    set-session

    # display path to current session file
    c8y sessions get --select path -o csv
    ```

2. Either checkout this repository, or just copy the [copy-measurements.sh](./copy-measurements.sh) script contents to a file locally

    ```sh
    chmod +x copy-measurements.sh
    ```

3. Switch to the session which is going to be the source tenant (where the measurements are going to be copied from)

4. Execute the script

    Example shows:

        * Copying measurements between "2022-01-01" to "2022-03-31" for 4 devices with ids: 1111, 2222, 3333 and 4444

    ```sh
    ./copy-measurements.sh --destination /home/user/my-destination-tenant.json --dateFrom "2022-01-01" --dateTo "2022-03-31" 1111 2222 3333 4444
    ```

## Help

```sh
Usage:
    ./examples/copy-measurements-to-tenant/copy-measurements.sh --destination <session_config> [--workers <number>] [--delay <duration>] [--dateFrom <date|relative>] [--dateTo <date|relative>] <DEVICE> [...DEVICE]

Example 1: Copy all measurements (since 1 year) for a single device

    ./examples/copy-measurements-to-tenant/copy-measurements.sh --destination targetTenantConfig.json 12345

Example 2: Only copy devices with ids 11111 22222 33333 between dates 100d ago to 7 days ago

    ./examples/copy-measurements-to-tenant/copy-measurements.sh --destination targetTenantConfig.json --dateFrom -100d --dateTo -7d 11111 22222 33333


Arguments:

  DEVICE : List of devices (as positional arguments)
  --workers <int> : Number of concurrent workers to create the measurements
  --destination <string> : Session destination where the measurements will be copied to
  --dateFrom <date|relative_date> : Only include measurements from a specific date
  --dateTo <date|relative_date> : Only include measurements to a specific date
  --delay <interval> : Delay between after each concurrent worker. This is used to rate limit the workers (to protect the tenant)
```
