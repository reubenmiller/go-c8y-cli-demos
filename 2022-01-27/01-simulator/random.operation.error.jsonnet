
# List of possible failure reasons
local error_reasons = [
    'Failed to download the package',
    'No space left on device',
    'Package was not found in Debian repository',
    'Unknown error',
];

{
    status: if _.Int(0, 100) >= var("threshold", 50) then 'SUCCESSFUL' else 'FAILED',

    # Conditional field
    failureReason: if $.status == 'FAILED' then error_reasons[_.Int(0,3)],
}