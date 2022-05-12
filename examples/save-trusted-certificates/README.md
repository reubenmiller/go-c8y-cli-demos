## save-trusted-certificates

This script looks for any of the Trusted certificates in the current session, and saves them to file in a .pem (x509 base64 ASCII format).

## Usage

1. Start a go-c8y-cli session

2. Run the script to save any trusted device certificates to file (in the current working directory)

    ```sh
    ./save-certs.sh
    ```

