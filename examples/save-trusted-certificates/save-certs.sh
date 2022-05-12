#!/bin/bash

while read -r DATA; do
    NAME=$( echo "$DATA" | c8y util show --select name -o csv | sed 's/.pem$//' )

    CERT_CONTENT=$( echo "$DATA" | c8y util show --select certInPemFormat -o csv | fold -w 65 )
    CERT_CONTENT=$( echo -e "-----BEGIN CERTIFICATE-----\n$CERT_CONTENT\n-----END CERTIFICATE-----\n" )

    OUTPUT_FILE="${NAME// /_}.pem"
    echo "Saving certificate [name=$NAME] to: $OUTPUT_FILE"
    echo "$CERT_CONTENT" > "$OUTPUT_FILE"

done < <( c8y api "/tenant/tenants/$C8Y_TENANT/trusted-certificates?pageSize=1000" )
