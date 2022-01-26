
local suffix = var("suffix", "");

local software_item(name, version) = {'name': name + suffix, 'version': version, 'url': ''};

{
    c8y_SoftwareList: [
        software_item("vim", "1.0.1"),
        software_item("htop", "2.0.1"),
    ]
}