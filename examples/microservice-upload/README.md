
* Try to pass environments

* Use .gitattributes to control files which should have specific line endings (rather than using dos2unix)
* Change execution bit before checking scripts into the repository (saves having to do chmod +x)

* Why docker?
    * Remove dependencies as much as possible


* Use environment variables rather than passing fixed arguments around
    * Timeout can be set globally via

    ```sh
    export C8Y_SETTINGS_DEFAULTS_PAGESIZE=120s
    ```


* Try to align with the go-c8y-cli settings as much as possible (as it provides a better user experience)
    * Current converts positional arguments to named arguments
    * 

### bash


#### Use arrays to build variadic arguments

```sh

```

#### Switch mistakes

```sh
## Arguments handler
subscribe=true
REST_ARGS=()
PARAMS=()
# Parse command-line options
while [[ $# -gt 0 ]]; do
  case "$1" in
    --skipSubscription)
      subscribe=false
      ;;
    --timeout|-timeout)
      if [ $# -gt 1 ]; then
        PARAMS+=("$1 $2")
        export C8Y_SETTINGS_DEFAULT
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
```

#### Always use `set -e` to stop on unexpected errors

```sh
#!/bin/bash

set -e

# Do other stuff
```


#### Calling from bash you can automatically from the calling shell

```sh
set-session

# Just pass all required
docker run --rm --env-file <(env | grep "^C8Y_") -it alpine sh
```


#### Remove dependency on jq if you can

```sh
check_current_tenant() {
  C8Y_TENANT=$(c8y currenttenant get --select "name" -o csv)
  if [[ -z "$C8Y_TENANT" ]]; then
    echo "Error: Failed to get tenant info."
    exit 5
  fi
  export C8Y_TENANT
}
```

* Don't use both curl and wget, pick one (less dependencies) - my preference is for curl

```sh
function download_microservice() {
  repo_url="$1"
  gh_response=$(curl -s "$repo_url")

  # extract the download URL of the first asset
  asset_url=$(c8y util show --input "$gh_response" --select "assets.0.browser_download_url" -o csv)
  asset_name=$(basename "$asset_url")

  # Note: You might run into api throttling if don't provide a gh token
  # Prefer using an if block and don't check the exit code later (as that is done by the if block)
  # And generally a if block reads better than a if/else block
  echo "Downloading assets $asset_name..."
  if ! curl "$asset_url" -o "$asset_name"; then
    echo "Download $asset_name failed"
    exit 2
  fi

  echo "Download $asset_name completed"
  return 0
}
```
