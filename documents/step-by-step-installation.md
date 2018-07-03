# Step by Step Installation

The ``scripts/deploy-jupyterhub.sh`` script provides an all in one way of creating the complete JupyterHub deployment. This script is implemented to run a series of other scripts. These scripts can be run separately if you want to instead run each step one at a time.

These scripts are:

* [scripts/create-notebooks-directory.sh](../scripts/create-notebooks-directory.sh) - Mounts the NFS volume to hold users Jupyter notebooks and creates the sub directory to be used for the course.
* [scripts/create-database-directory.sh](../scripts/create-database-directory.sh) - Mounts the NFS volume to hold the JupyterHub database and creates the sub directory to be used for the course.
* [scripts/create-notebooks-volume.sh](../scripts/create-notebooks-volume.sh) - Creates the persistent volume resource definition in OpenShift for the volume to hold the users Jupyter notebooks for the course.
* [scripts/create-database-volume.sh](../scripts/create-database-volume.sh) - Creates the persistent volume resource definition in OpenShift for the volume to hold the JupyterHub database for the course.
* [scripts/create-project.sh](../scripts/create-project.sh) - Creates the project for the course and loads the template used to deploy JupyterHub.

If running the scripts one at a time instead of using ``scripts/deploy-jupyterhub.sh``, you still need to perform the deployment. This can be done using the loaded template, from the command line or the web console.

## Creating the Directories

Creation of the directories is handled using the ``scripts/create-notebooks-directory.sh`` and ``scripts/create-database-directory.sh`` scripts. These scripts need to be supplied two inputs.

* ``Course Name`` - The name identifying the course. This must consist of only lower case letters, numbers, and the dash character.
* ``Version Number`` - An optional version number or instance count. This should be left empty unless needing to create a separate new instance of the directory for the same course. This would only be needed where needing to start over with a new persistent volume for a course without needing to re-create the whole JupyterHub deployment.

These inputs can be supplied as command line arguments. If not supplied as command line arguments, the script will prompt for the values.

These scripts must be run using as super user by using ``sudo`` as they will mount the appropriate NFS volume from the NFS server and create the required sub directory for the course. The name of the sub directory created will have the format ``notebooks-$COURSE_NAME-pv$VERSION_NUMBER`` for the notebooks and ``database-$COURSE_NAME-pv$VERSION_NUMBER`` for the database.

The details of the NFS server and NFS volume is coded into the respective scripts. If during testing you need to override these values, you can set the ``NFS_SERVER_NAME`` and ``NFS_SERVER_SHARE`` environment variables.

For exact details of the steps performed by the scripts, see the code for the respective scripts.

## Creating the Volumes

Creation of the persistent volume resource definitions is handled using the ``scripts/create-notebooks-volume.sh`` and ``scripts/create-database-volume.sh`` scripts. These scripts need to be supplied two inputs.

* ``Course Name`` - The name identifying the course. This must consist of only lower case letters, numbers, and the dash character.
* ``Version Number`` - An optional version number or instance count. This should be left empty unless needing to create a separate new instance of the directory for the same course. This would only be needed where needing to start over with a new persistent volume for a course without needing to re-create the whole JupyterHub deployment.

These inputs can be supplied as command line arguments. If not supplied as command line arguments, the script will prompt for the values.

These scripts must be run from a UNIX user account for which ``oc`` is already logged into the OpenShift cluster as a cluster admin. This is because the scrips will create persistent volume resource definitions for the notebooks and database volumes for the course.

The templates used in creating the persistent volumes are:

* [templates/notebooks-volume.json](../templates/notebooks-volume.json) - Template for the persistent volume created for the notebooks.
* [templates/database-volume.json](../templates/database-volume.json) - Template for the persistent volume created for the database.

The persistent volume for the notebooks will have type ``ReadWriteMany`` as it needs to be mounted on the pods for JupyterHub as the Jupyter notebooks instances for each user. When mounting the persistent volume on the pod for the JupyterHub volume, the root directory of the volume will be mounted. When mounting the persistent volume on the pod for the Jupyter notebooks of a normal user, only the sub directory corresponding to that user will be mounted. If a user creates their Jupyter notebook instance and they are nominated as an admin user in JupyterHub, they will be able to see sub directories for all users and browse files of any user.

The persistent volume for the database will have type ``ReadWriteOnce``. It will only be mounted into the pod for the PostgreSQL database instance used by JupyterHub.

The names of the persistent volumes created will have the format ``$COURSE_NAME-notebooks-pv$VERSION_NUMBER`` and ``$COURSE_NAME-database-pv$VERSION_NUMBER``. Because the directories are named for the source, the persistent volume will be created with a claim reference, so it can only be used by the Jupyter deployment for that course. This way nothing else deployed to the OpenShift cluster can inadvertently claim the persistent volumes.

The reclaim policy for the persistent volumes is set to ``Retain``. This means that when the persistent volume claims are deleted along with the JupyterHub deployment, the persistent volume will not be automatically cleared. To clean up the persistent volume will require manual intervention to delete the directory on the NFS server, along with the persistent volume resource definition. This is so that contents of the directory can be retained if necessary at the end of the course for any reason.

The details of the NFS server and NFS volume is coded into the respective scripts. If during testing you need to override these values, you can set the ``NFS_SERVER_NAME`` and ``NFS_SERVER_SHARE`` environment variables.

The name of the JupyterHub deployment is also coded into the scripts. This defaults to ``jupyterhub``. If during testing you need to override this value, you can set the ``JUPYTERHUB_DEPLOYMENT`` environment variable.

For exact details of the steps performed by the scripts, see the code for the respective scripts. Also consult the respective templates.
