The directory contains build scripts and a template for building a Jupyter
notebook image based off the official Jupyter Project base images. Steps
are also included for modifying a standard deployment of JupyterHub for
a course, to use the image built from this image.

The steps are:
 
STEP 1: Deploy a JupyterHub instance for a new course name using:

```
scripts/deploy-jupyterhub.sh
```

You should use a sample for the notebook repository. This will be replaced
in subsequent steps.

A sample notebook repository you can use is:

* Notebook Repository URL: `https://github.com/jupyter-on-openshift/poc-hub-singapore-ntu`
* Notebook Repository Context Dir: `samples/empty`
* Notebook Repository Reference: `master`

STEP 2: Change the active OpenShit project using the `oc project` command to
be the same project as the course was deployed into. Run the following
command against the Git repository for the notebook you want to use with
the Jupyter Project notebook images:

```
oc new-app https://raw.githubusercontent.com/jupyter-on-openshift/poc-hub-singapore-ntu/master/builder/templates.json \
  --param GIT_REPOSITORY_URL=https://github.com/jupyter-on-openshift/poc-hub-singapore-ntu \
  --param CONTEXT_DIR=samples/rdkit
```

Change the `GIT_REPOSITORY_URL` and `CONTEXT_DIR` as necessary to values
for the Git repository for your notebook. You can also pass the
`GIT_REFERENCE` template parameter if need to use branch other than the
`master` branch of the Git repository.

This should result in an image stream being created for the image called
`notebook`.

STEP 3: Edit the config map `jupyterhub-cfg` in the course project. This
can be done in the web console under "Resources->Config Map".

STEP 4: In the `jupyterhub_config.py` section of the `jupyterhub-cfg` config
map, add:

```
volume_mounts_user = [
    {
        'name': 'notebooks',
        'mountPath': '/home/jovyan',
        'subPath': 'users/{username}'
    }
]

volume_mounts_admin = [
    {
        'name': 'notebooks',
        'mountPath': '/home/jovyan/users',
        'subPath': 'users'
    }
]

def modify_pod_hook(spawner, pod):
    if spawner.user.admin:
        volume_mounts = volume_mounts_admin
        workspace = interpolate_properties(spawner, 'users/{username}/workspace')
    else:
        volume_mounts = volume_mounts_user
        workspace = 'workspace'

    os.makedirs(interpolate_properties(spawner,
            '/opt/app-root/notebooks/users/{username}'), exist_ok=True)

    pod.spec.containers[0].env.append(dict(name='JUPYTER_MASTER_FILES',
            value='/opt/conda/master'))
    pod.spec.containers[0].env.append(dict(name='JUPYTER_WORKSPACE_NAME',
            value=workspace))
    pod.spec.containers[0].env.append(dict(name='JUPYTER_SYNC_VOLUME',
            value='true'))

    pod.spec.containers[0].volume_mounts.extend(
            expand_strings(spawner, volume_mounts))

    pod.spec.security_context.supplemental_groups = [100]

    return pod

c.KubeSpawner.modify_pod_hook = modify_pod_hook

c.KubeSpawner.singleuser_image_spec = 'notebook:latest'

c.KubeSpawner.cmd = ['/tmp/scripts/run']
```

Avoid using tabs. The indentation in the function should be 4 spaces.

STEP 5: Redeploy the JupyterHub instance by running:

```
oc rollout latest dc/jupyterhub oc rollout status dc/jupyterhub
```

STEP 6: Visit the JupyterHub URL.
