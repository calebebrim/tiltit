# How to use it?

```python
load('ext://git_resource', 'git_resource')

repo = git_resource("https://github.com/calebebrim/tiltit.git", ref="master")

load(repo.child("Tiltfile"), "install_postgres", "install_kafka", "install_redis", "install_minio", "install_superset", "install_superset_helm", "helm_install", "install_infra")

# Now use the helpers:

install_infra(labels=["infrastructure"], services=["postgres", "redis", "kafka", "superset_helm"])
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
