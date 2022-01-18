
## Overview

Deployment scripts and Github workflow to deploy a web application and only keeps the last N deployed application binaries.

## Workflow

The github action workflow is located here:

`2022-01-27/.github/workflows/deploy-example02.yml`

## Workflow steps

1. Deploy a web application from a folder
2. Delete older deployed application binaries (keeping last N binaries)
3. Add tenant option related to the web application

## Triggering a github workflow via gh cli

```sh
gh workflow run -R reubenmiller/go-c8y-cli-demos deploy-example02 -f keep_last=5
```
