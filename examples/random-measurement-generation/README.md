## Create random number of measurements per device

### Option 1: Use c8y api with templates

A custom jsonnet template can be used to generate multiple measurements using the bulk measurement api, where the template generates a variable number of measurement, but it only sends one request to the measurement endpoint per device.

The template uses one template variable which lets the user to control the max number of measurements.

Below shows an example of creating 1 to 3 measurements per device which is returned by `c8y devices list`.

```sh
c8y devices list \
| c8y api \
    --method 'POST' \
    --url '/measurement/measurements' \
    --contentType 'application/vnd.com.nsn.cumulocity.measurementcollection+json' \
    --template ./measurement.jsonnet --templateVars max=3
```
