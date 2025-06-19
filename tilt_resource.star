


def tilt_resource(resource_name, repo_url="git@github.com:calebebrim/tiltit.git", enable_local_resource=True, tilt_resources_path= "/tmp/tilt/resources", labels=[], deps=[], branch="master"):
    # Define a local resource to clone or update the repo

    tilt_resources_path = tilt_resources_path.strip()

    local_repo_path = os.path.join(tilt_resources_path, resource_name)
    local_repo_path_exists=os.path.exists(local_repo_path)
    tilt_resources_path_exists=os.path.exists(tilt_resources_path)
   
    print("Local repo {name}: {exists}".format(name=resource_name, exists=local_repo_path_exists))
    print("Tilt resources: {exists}".format(name=resource_name, exists=tilt_resources_path_exists))

    if not tilt_resources_path_exists:
        print("Creating tilt repo path path: {}".format(tilt_resources_path))
        local("mkdir -p {}".format(tilt_resources_path))
    # Load code after cloning
    if local_repo_path_exists:
        print("Repository {} already exists at: {}".format(resource_name, tilt_resources_path))
        local("cd {} && git pull origin master".format(local_repo_path), quiet=True)
    else:
        print("loading tilt resource from {url} into {path}".format(url=repo_url, path=local_repo_path))
        local("git clone {url}#master {path}".format(url=repo_url, path=local_repo_path), quiet=True)

    # Enable checking out new tilt repo
    local_resource(
        resource_name,
        cmd = '''
            if [ ! -d "{path}" ]; then
                git clone {url} {path}
            else
                cd {path} && git pull
            fi
        '''.format(path=local_repo_path, url=repo_url),
        deps = deps,            # Runs on tilt up
        labels = labels,
        trigger_mode = TRIGGER_MODE_MANUAL,  # Run when manually triggered
    )
    
    resource_lib = load_dynamic('{}/Tiltfile'.format(local_repo_path))
    return resource_lib
    