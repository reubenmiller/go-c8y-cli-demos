// Use local variables
local key = _.Int(1000,9999);

{
    text: "A dummy event %s" % $.cli_Details.key,
    type: "c8y_dummyEvent_" + $.cli_Details.key,

    // Simulate a delay in the creation time
    time: _.Now('-%ss' % _.Int(1, 5)),

    // Custom fragment to store additional details about the event
    cli_Details: {
        key: key,

        // Simulate a delay in the 
        machineTime: $.time,
    },
}