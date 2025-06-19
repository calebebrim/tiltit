

load('ext://helm_resource', 'helm_resource', 'helm_repo')
load('./Tiltfile.blobs.star', 'kafka_yaml', 'kafka_storage_yaml', 'POSTGRE_YAML', 'REDIS_YAML', 'MINIO_YAML')



def install_postgres(labels=[]):
    k8s_yaml(POSTGRE_YAML)
    k8s_resource('postgres', port_forwards=5432, labels=labels)


def install_kafka(labels=[], name='kafka'):
    helm_repo('helm-strimzi-charts', 'https://strimzi.io/charts/', labels=labels)
    helm_resource('kafka-operator', "strimzi/strimzi-kafka-operator", labels=labels)
    
    k8s_yaml(kafka_yaml(name=name, storage_class_name="kafka-storage"))
    k8s_yaml(kafka_storage_yaml(name, storage_class_name="kafka-storage", node_affinity=["kind-cluster-worker2"]))

    k8s_resource(
        new_name=name+'-storage',
        objects=[name+'-storage:persistentvolume'], labels=labels
    )
    k8s_resource(
        new_name=name+"-cluster",
        objects=[name+"-cluster", name+'-nodepool:kafkanodepool'], 
        labels=labels,
        resource_deps=["kafka-storage", "helm-strimzi-charts"]
    )
    k8s_resource('kafka-operator', labels=labels)

# tryed to use minio to simulate S3 storage, but it is not working
def install_minio():
    k8s_yaml(MINIO_YAML)
    k8s_resource(new_name='minio-storage', objects=["minio-pv:persistentvolume", "minio-pvc:persistentvolumeclaim"])
    k8s_resource(
        'minio',
        port_forwards=[9001, 9000], labels=['infrastructure']
    )

def install_redis(labels=[]):
    
    k8s_yaml(REDIS_YAML)
    k8s_resource(
        'redis', 
        objects=["redis-config"],
        port_forwards=[6379, 8001], 
        labels=labels,
        trigger_mode=TRIGGER_MODE_MANUAL

    )


def install_superset(labels):
    k8s_yaml('k8s/superset.yaml')
    k8s_resource(
        'superset',
        port_forwards=8088,
        labels=labels
    )

def helm_install(values_file, name, chart=None, repo_url=None, labels=[], namespace='default', resource_deps = [], deps=[], on_exist='skip'):
    """ 
    Install a Helm chart with the specified values file and name.
    """
    if repo_url:
        local('helm repo add myrepo {}'.format(repo_url))
        local('helm repo update')

    def get_helm_deployment_status(name):
        """Check if a Helm release is installed."""
        
        status = local('helm status {} | grep STATUS'.format(name), quiet=True)
        return status.strip().split(': ')[1] if status else ""
            
    def helm_deployment_present(name):
        """Check if a Helm release is present."""
        
        status = local('if helm list | grep -q {}; then echo "present"; else echo "missing"; fi'.format(name))
        return str(status).strip()

    status = helm_deployment_present(name)
    print('Helm status for {}: {}'.format(name, status))
    if status == 'present':
        print('Helm release {} already exists, skipping installation.'.format(name))
        if on_exist == 'skip':
            return
        elif on_exist == 'replace':
            local('helm uninstall {}'.format(name))
        else:
            fail('Unknown on_exist option: {}'.format(on_exist))
            return
    deps = deps + [values_file]
    chart = chart or '.'
    local_resource(
        'helm_install_{}'.format(name),
        cmd='helm upgrade --install {} {} --values {} --namespace {}'.format(
            name, chart, values_file, namespace
        ),
        deps=deps,
        resource_deps=resource_deps,
        labels=labels
    )
    
    watch_file(values_file)
    if chart != '.':
        watch_file(chart)

# Example usage:

def install_superset_helm(labels=[]):
    """
    Install Apache Superset using Helm.
    """
    # helm_repo('superset-repo', 'https://apache.github.io/superset', labels=['infrastructure'])
    docker_build(
        'apache/superset',
        context='./docker',
        dockerfile='./docker/superset.dockerfile',
    )

    helm_install(
        './k8s/superset-helm-values.yaml', 
        name="superset", 
        chart="superset/superset", 
        repo_url='https://apache.github.io/superset', 
        on_exist='replace',
        labels=labels,
    )

def install_infra(labels, services=[]):
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

    if 'postgres' in services:
        install_postgres(labels)
    if 'redis' in services:
        install_redis(labels)
    if 'kafka' in services:
        install_kafka(labels)
    if 'minio' in services:
        install_minio(labels) # << not working
    if 'superset' in services:
        install_superset(labels)
    if 'superset_helm' in services: 
        install_superset_helm(labels)
