v1alpha1.extension_repo(name='tiltit', url='https://github.com/calebebrim/tiltit')




def install_infra(services=("kafka", "postgres", "redis")):
    modules = {}
    for module in services:
        v1alpha1.extension(name=module, repo_name='tiltit', repo_path="deployments/{}".format(module))

        modules[module] = load_dynamic("ext://{}".format(module))


        modules[module]["install"](labels=["infra.{}".format(module)])
    return modules