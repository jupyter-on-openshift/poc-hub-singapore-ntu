# Quick Start Installation

The example provides scripts for deploying and managing the JupyterHub instance. When the scripts are used, they will create a new project for the JupyterHub deployment. This project will be named after the course.

To use the scripts, you need to checkout a copy of the repository. This needs to be done on a host where you have super user access, and which can mount volumes from the NFS server providing persistent storage. The user should also have cluster admin rights for the OpenShift cluster.

For the cluster the example was developed for, a master node in the OpenShift cluster was used.

Once you have checked out a copy of the repository, the script you need to run is:

* [scripts/deploy-jupyterhub.sh](../scripts/deploy-jupyterhub.sh)

This script must be run as the super user, using ``sudo``. This is because it needs to mount volumes from the NFS server to setup directories within the volume.

When the script is run, it will prompt you for a number of inputs. These are:

* ``Course Name`` - The name identifying the course. This must consist of only lower case letters, numbers, and the dash character. This will be used as the project name and will also appear in the generated hostname for the JupyterHub instance.
* ``Notebook Repository URL`` - The URL of the Git repository which hosts the Jupyter notebook and data files for the course.
* ``Notebook Repository Context Dir`` - The directory within the Git repository which contains the Jupyter notebook and data files, along with the ``requirements.txt`` file listing what Python packages are required for the Jupyter notebooks. This should be left empty if files are in the root of the Git repository.
* ``LDAP Search User`` - The name of the LDAP user account used to perform searches against the LDAP authentication servers.
* ``LDAP Search Password`` - The password for the LDAP user account used to perform searches against the LDAP authentication servers.
* ``JupyterHub Admin Users`` - A list of the LDAP users who should initially be granted JupyterHub admin rights. The names of each user should be separate by whitespace. This can be left empty as the names can be updated later.

Example output when running the script is:

```
$ sudo scripts/deploy-jupyterhub.sh
Course Name: jakevdp
Notebook Repository URL: https://github.com/jakevdp/PythonDataScienceHandbook
Notebook Repository Context Dir:
LDAP Search User: ldap-username
LDAP Search Password:
JupyterHub Admin Users: admin-username
Continue? [Y/n] y

persistentvolume "jakevdp-notebooks-pv" created
persistentvolume "jakevdp-database-pv" created
Now using project "jakevdp" on server "https://...:8443".

You can add applications to this project with the 'new-app' command. For example, try:

    oc new-app centos/ruby-22-centos7~https://github.com/openshift/ruby-ex.git

to build a new example application in Ruby.
template "jupyterhub" created
--> Deploying template "jakevdo/jupyterhub" to project jakevdp

     * With parameters:
        * APPLICATION_NAME=jupyterhub
        * COURSE_NAME=jakevdp
        * NOTEBOOK_REPOSITORY_URL=https://github.com/jakevdp/PythonDataScienceHandbook
        * NOTEBOOK_REPOSITORY_CONTEXT_DIR=
        * LDAP_SEARCH_USER=ldap-username
        * LDAP_SEARCH_PASSWORD=...
        * JUPYTERHUB_ADMIN_USERS=admin-username
        * JUPYTERHUB_ENROLLED_USERS=
        * JUPYTERHUB_IDLE_TIMEOUT=3600
        * JUPYTERHUB_ENABLE_LAB=false
        * POSTGRESQL_VOLUME_SIZE=512Mi
        * NOTEBOOK_VOLUME_SIZE=25Gi
        * NOTEBOOK_MEMORY=512Mi
        * JUPYTERHUB_CONFIG=
        * PYTHON_IMAGE_NAME=python:3.6
        * POSTGRESQL_IMAGE_NAME=postgresql:9.6
        * DATABASE_PASSWORD=... # generated
        * COOKIE_SECRET=... # generated

--> Creating resources ...
    configmap "jupyterhub-cfg" created
    serviceaccount "jupyterhub-hub" created
    rolebinding "jupyterhub-edit" created
    imagestream "jupyterhub-hub-s2i" created
    buildconfig "jupyterhub-hub-s2i" created
    imagestream "jupyterhub-hub-img" created
    buildconfig "jupyterhub-hub-img" created
    persistentvolumeclaim "jupyterhub-notebooks" created
    secret "jupyterhub-ldap" created
    secret "jupyterhub-pgsql" created
    deploymentconfig "jupyterhub" created
    service "jupyterhub" created
    route "jupyterhub" created
    persistentvolumeclaim "jupyterhub-database" created
    deploymentconfig "jupyterhub-database" created
    service "jupyterhub-database" created
    imagestream "jupyterhub-nb-s2i" created
    buildconfig "jupyterhub-nb-s2i" created
    imagestream "jupyterhub-nb-bld" created
    buildconfig "jupyterhub-nb-bld" created
    imagestream "jupyterhub-nb-img" created
    buildconfig "jupyterhub-nb-img" created
--> Success
    Build scheduled, use 'oc logs -f bc/jupyterhub-hub-s2i' to track its progress.
    Build scheduled, use 'oc logs -f bc/jupyterhub-hub-img' to track its progress.
    Access your application via route 'jupyterhub-jakevdp...'
    Build scheduled, use 'oc logs -f bc/jupyterhub-nb-s2i' to track its progress.
    Build scheduled, use 'oc logs -f bc/jupyterhub-nb-bld' to track its progress.
    Build scheduled, use 'oc logs -f bc/jupyterhub-nb-img' to track its progress.
    Run 'oc status' to view your app.
```
