# AKS Chaos Zone experiment

## Overview

This project utilizes Bicep files to define and deploy Azure infrastructure resources. It will deploy
* AKS
* ACR
* Chaos experiment
* and some helper resources
## Chaos Engineering Concepts

### AKS Chaos Engineering

Chaos engineering is the practice of intentionally introducing failures into a system to test its resilience and identify weaknesses before they cause real outages. In the context of Azure Kubernetes Service (AKS), this involves simulating various failure scenarios (like node failures, network latency, or entire availability zone outages) to understand how the cluster and the applications running on it behave under stress. The goal is to build confidence in the system's ability to withstand turbulent conditions in production.

### Zone Outage Experiment

This project specifically implements an AKS Chaos Studio experiment that simulates an Availability Zone (AZ) outage. Azure regions with Availability Zones provide high availability by having physically separate datacenters within the region. An AKS cluster configured with multiple AZs should be resilient to a single zone failure.

This experiment targets AKS node pools spread across multiple zones and simulates the unavailability of one of those zones. By running this experiment, you can verify:
* If Kubernetes correctly identifies nodes in the failed zone as unhealthy.
* If workloads running on nodes in the affected zone are successfully rescheduled to nodes in healthy zones.
* If application availability is maintained throughout the simulated outage.
* The time it takes for the system to recover.

### Pod Disruption Budgets (PDBs)

Kubernetes Pod Disruption Budgets (PDBs) are a crucial mechanism for ensuring application availability during voluntary disruptions, such as node maintenance or upgrades, and can also play a role during involuntary disruptions like the zone outage simulated here.

A PDB limits the number of Pods of a replicated application that are simultaneously unavailable. You can define a PDB using `minAvailable` (a number or percentage of pods that must remain available) or `maxUnavailable` (a number or percentage of pods that can be unavailable).

When a disruption event occurs (like draining a node), Kubernetes respects the PDB. It will prevent the disruption from proceeding if it would violate the budget defined by the PDB, thus ensuring a minimum level of service availability. In the context of a zone outage, while PDBs primarily control voluntary disruptions, understanding how they interact with scheduler behavior during rescheduling is important for predicting application availability. For instance, if `maxUnavailable` is set too low, it might slow down rescheduling onto healthy nodes if other voluntary disruptions are happening concurrently. Conversely, if not set, too many pods might be taken down at once during planned maintenance, reducing resilience before an unplanned event like a zone outage even occurs.


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
Supported arguments:
   up                    : Bring up the azure infrastructure
   down                  : Delete the infrastructure
   deploy                : Deploy test nginx workload
   start                 : Start the chaos experiment
   stop                  : Stop the chaos experiment
   watch                 : Watch the workload
   aks-creds             : Get AKS credentials
```

## Debug

To debug script simple export DEBUG=1