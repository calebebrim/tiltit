# Description

Tiltit is a developer utils to encapsulate the deployment logic of some tools. 


# How to use it?

Add this to your main Tiltfile. It will download the tilt_resource helper at same path as ``tilt_resource.star``. To update this file you just need to delete it, the following script will redownload the latest version:

```python
# 1. Map the repository
v1alpha1.extension_repo(name='tiltit', url='https://github.com/calebebrim/tiltit')
# 2. Map the extension
v1alpha1.extension(name="tiltit", repo_name='tiltit', repo_path=".")

# 3. Use it
load("ext://tiltit", "install_infra")

install_infra(services=['kafka'])

# Also is possible to map the module direclty
v1alpha1.extension(name="kafka", repo_name='tiltit', repo_path="deployments/kafka")
load("ext://kafka", kafka_install="kafka")
#or
kafka = load_dynamic("ext://tiltit")
kafka["install"]()

```

Install multiple infrastructure services at once. `services` is a list which can include:

* `postgres`
* `redis`
* `kafka`
* `minio` (currently not working)
* `superset` (currently not working)
* `superset_helm` (currently not working)

Example:

```python
install_infra(services=["postgres"])
```


# Using the modules directly

Create a [module] deployment
```python


v1alpha1.extension(name="[module]", repo_name='tiltit', repo_path="deployments/[module]")
load("ext://[module]", [module]_install="[module]")
```

