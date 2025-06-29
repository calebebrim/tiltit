v1alpha1.extension_repo(name='tiltit', url='https://github.com/calebebrim/tiltit')




def install_infra(services=("kafka", "postgres", "redis"), options={}):
    """
    Install infrastructure services like Kafka, Postgres, and Redis.
    """
    print(options)
    modules = {}
    for module in services:
        v1alpha1.extension(name=module, repo_name='tiltit', repo_path="deployments/{}".format(module))

        modules[module] = load_dynamic("ext://{}".format(module))
        print("installing infra module: {}".format(module))
        if module in options:
            print("module {} options: {}".format(module, options.get(module)))
            modules[module]["install"](labels=["infra.{}".format(module)], options=options.get(module))
        else: 
            modules[module]["install"](labels=["infra.{}".format(module)])
    return modules