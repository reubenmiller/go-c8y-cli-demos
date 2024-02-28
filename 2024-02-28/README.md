# go-c8y-cli extensions?

Duration: 1 hour (including 15mins Q&A)

* Introduction to go-c8y-cli extensions
* How to use extensions
* How to build & contribute an extension
* Q&A

## Introduction to go-c8y-cli extensions

### Who are extensions for?

* Developers building UIs or microservices
* Working on a customer project with custom data models
* Solutions maintainer
* Platform maintainer / Support

### Anatomy of an extension

*Extensions just expose already existing features in a convenient package*

An extension is just a folder containing files and folders defining different functionality (e.g. commands, views, templates).

The folder can be made shareable by committing it to a git repository.

[Extensions docs](https://goc8ycli.netlify.app/docs/concepts/extensions/)

* aliases
* commands
* views
* templates

## How to use extensions

**Install**

```sh
c8y extension install <path|git_repo>
```

**List**

```sh
c8y extension list
```

**Use**

```sh
c8y <extension_name> ...
```

**Updating**

```
c8y extensions update --all
```

### Commands

Commands are grouped under the extension name (without the `c8y-` prefix).

```sh
c8y demo microservices health --id advanced-software-mgmt
```

### Views/templates

Views and templates included by an extension can be referenced via the corresponding arguments using the syntax `<extension>::`:

```sh
c8y devices create --template demo::device.jsonnet --name hello
```

```sh
c8y microservices list --view demo::ms/tenantowner -p 100
```

## How to build & contribute an extension

A [comprehensive tutorial](https://goc8ycli.netlify.app/docs/tutorials/extensions/) is provided on the documentation website

### Use cases

* Create extension to compliment your microservice API
* Project specific views and templates
* Support new Cumulocity IoT api before it is supported by go-c8y-cli (e.g. advanced software management api)
* Script kitty for personal usage

### Types of commands

#### API Based commands

Command are defined by a yaml syntax which is very similar to the spec used by go-c8y-cli to generate all of the commands.

A simple example:

```sh
c8y demo microservices health --id advanced-software-mgmt | jq
```

A more detailed example:

```sh
c8y demo software
```

These commands have the advantage that they are a much more comprehensive user experience as the full tab completion is available (e.g. complete microservices, devices etc.)

#### Shell based commands

Commands can also be created as shell commands

* [c8y-demo/commands/lab/prepare](./c8y-demo/commands/lab/prepare)
* [c8y-demo/commands/lab/list](./c8y-demo/commands/lab/list)

**Disadvantages**

* Requires a shell, so it is less portable for Window's users
* Only global flags are tab completed, other custom flags provided by the script are not

## Discovering Extensions

Find extensions on Github via the **go-c8y-cli-extension** topic:

* https://github.com/topics/go-c8y-cli-extension

### Existing extensions

* https://github.com/thin-edge/c8y-tedge
* https://github.com/SoftwareAG/c8y-bpl
* https://github.com/SoftwareAG/c8y-oee
* https://github.com/reubenmiller/c8y-devmgmt
* https://github.com/reubenmiller/c8y-defaults
* https://github.com/reubenmiller/c8y-simulation


## Future work

* Also support binary based extensions (which will enable support for tab completion)
