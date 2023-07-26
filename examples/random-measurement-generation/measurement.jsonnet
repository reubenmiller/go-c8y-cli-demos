# application/vnd.com.nsn.cumulocity.measurementcollection+json
local create(device_id, type="example") = 
    {
        type: type,
        source: {
            id: device_id,
        },
        time: _.Now(),
        environment: {
            temperature: {
                value: _.Float(1, 5)
            }
        }
    }
;

local max_count = _.Int(1, var("max", 10));
{
    "max_count": max_count,
    "measurements": [
        create(input.value.id)
        for i in std.range(0, max_count-1)
    ]
}