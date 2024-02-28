// Helper: Create software entry
local newSoftware(i) = {
    name: "app" + i,
    version: "1.0." + i,
    softwareType: "dummy",
    url: "",
};

local deviceTypes = [
    "macOS",
    "Windows",
    "linux",
];

// name: var("name", "exampledevice_") + std.format("%04d", input.index)

// Output: Device Managed Object
{
    name: var("name", "device001"),
    c8y_IsDemo: {},
    type: "lab",
    "os": deviceTypes[_.Int(std.length(deviceTypes))],
    // ["c8y_" + var("type")]: {},
    c8y_SupportedOperations: [
        "c8y_SoftwareUpdate",
    ],
    c8y_SoftwareList: [
        newSoftware(i)
        for i in std.range(1, _.Int(var("softwareCount", 1), 1))
    ],
}

