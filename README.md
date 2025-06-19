# Description

Tiltit is a developer utils to encapsulate the deployment logic of some tools. 


# How to use it?

Add this to your main file. It will download the tilt_resource helper at same path as ``tilt_resource.star``. To update this file you just need to delete it, the following script will redownload the latest version:
```python
if not os.path.exists("./tilt_resource.star"):
    # 1. Fetch the raw file from GitHub URL
  local('curl -L https://raw.githubusercontent.com/calebebrim/tiltit/refs/heads/master/tilt_resource.star -o tilt_resource.star', quiet=True)

# 2. Load tilt_resource
load("tilt_resource.star", "tilt_resource")

#3. Use your Tiltfile 
tiltit = tilt_resource("tiltit_repo")

install_infra = tiltit["install_infra"]

install_infra(labels=[], services=['kafka'])
```

# Helper functions

## `install_postgres(labels=[])`

Install a PostgreSQL instance and forward port 5432.

## `install_kafka(labels=[], name='kafka')`

Install Strimzi Kafka Operator via Helm and deploy a Kafka cluster and storage with configurable storage class and node affinity.

## `install_redis(labels=[])`

Deploy Redis and configure port forwards for Redis and its web UI (6379, 8001). Trigger mode is manual.

## `install_minio()`

Deploy a MinIO instance (note: currently marked as not working).

## `install_superset(labels)`

Deploy Apache Superset using a K8s YAML manifest and forward port 8088.

## `helm_install(values_file, name, chart=None, repo_url=None, labels=[], namespace='default', resource_deps=[], deps=[], on_exist='skip')`

General-purpose Helm install helper. Adds Helm repo (if given), checks if release exists, and upgrades or installs with given values. Watches values file for changes.

## `install_superset_helm(labels=[])`

Build a custom Superset Docker image and install Superset using Helm with the provided values file and chart.

## `install_infra(labels, services=[])`

Install multiple infrastructure services at once. `services` is a list which can include:

* `postgres`
* `redis`
* `kafka`
* `minio` (currently not working)
* `superset`
* `superset_helm`

Example:

```python
install_infra(labels=["infrastructure"], services=["postgres", "kafka"])
```
