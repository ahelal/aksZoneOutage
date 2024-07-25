# AKS Chaos Zone experiment

## Overview

This project utilizes Bicep files to define and deploy Azure infrastructure resources. It will deploy
* AKS
* ACR
* Chaos experiment
* and some helper resources


## Prerequisites

* Azure subscription with the necessary permissions to create and manage resources
* Azure CLI (version 2.62.0 or later)
* Azure Bicep CLI Module
* Python 3
* kubectl

## Check default configuration

To review the default configuration, navigate to the `config.env` file and make any necessary changes.

## Pave infra

Before executing the scripts, ensure that you are logged in to Azure by running the command `az login`.

The main shell script that orchestrates all the functions is located at `./scripts/paveInfra.sh`.

```
Supported arguments are:
    up                    : Bring up the Azure infrastructure
    down                  : Bring down the deployment
    deploy                : Deploy the test nginx workload
    watch                 : Watch the deployment
    aks-creds             : Get AKS credentials
```

## Debug

To debug script simple export DEBUG=1