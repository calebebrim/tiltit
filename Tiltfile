

load('ext://helm_resource', 'helm_resource', 'helm_repo')
load('./utils/Tiltfile', "listdir")


def install_infra(labels=[], services=[], base_path='.'):
    # needed to increase the upsert timeout for superset deployment 
    # update_settings ( max_parallel_updates = 3 , k8s_upsert_timeout_secs = 300 , suppress_unused_image_warnings = None ) 
    if not services:
        print("""No infra services defined! 
        usage: 
            install_infra('labels', services=[...])
        available services: 
            - postgres
            - redis
            - kafka
            - minio << not working
            - superset << not working
    """)
        return

    base_deployments_path = "{basepath}/deployments".format(basepath=base_path)
    deployments = listdir(base_deployments_path)
    print("Installing services:")
    for service in services:
        print("-> {}.".format(service))
        if service in deployments:
            mTiltfile = os.path.join(base_deployments_path, service, "Tiltfile")
            module = load_dynamic(mTiltfile)
            module["install"](labels=labels)
        else:
            fail("{} service not present".format(service))
    