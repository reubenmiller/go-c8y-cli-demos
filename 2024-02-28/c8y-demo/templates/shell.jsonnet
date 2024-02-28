// Description: Create custom operation
{
    deviceId: "1234", // Dummy value (this will be overwritten when using with c8y operations create)
    description: "Executing shell command: " + $.c8y_Command.text,
    c8y_Command: {
        text: var("shell", "echo hello world"),
    }
}