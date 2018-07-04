# Troubleshooting Issues

Issues could arise during the deployment of JupyterHub, or during its operation. A number of issues are described below along with how to deal with them.

## Image Builds Failing

When JupyterHub is deployed, a number of builds are set up. These include both Source-to-Image (S2I) builds and docker type builds. The builds can fail due to networking issues due to the fact that the builds will pull down software packages from repositories such as the Python package index (PyPi) and Node package manager repository.

The list of build configurations created are:

* ``jupyterhub-hub-s2i`` - Creates a base image for JupyterHub. The result is an S2I builder image that can be run against a repository to incorporate custom configuration for a JupyterHub deployment with the base image.
* ``jupyterhub-hub-img`` - Creates a custom JupyterHub image, by running the ``jupyterhub-hub-s2i`` image as an S2I builder against the [jupyterhub](../jupyterhub) directory of this repository.
* ``jupyterhub-nb-s2i`` - Creates a base image running Jupyter notebooks. The result is an S2I builder image that can be run against a repository to incorporate a set of Jupyter notebooks with the base image, and installed required packages.
* ``jupyterhub-nb-bld`` - Creates a custom ``jupyterhub-nb-s2i`` image using a docker type build. This is to permit additional system packages for libraries required by Python packages to be installed.
* ``jupyterhub-nb-img`` - Creates a custom Jupyter notebook image, by running the ``jupyterhub-nb-bld`` image against the specifed remote Git repository containing the Jupyter notebooks for the course.

If a build fails, it is not necessary to destroy and recreate the deployment. Instead the failing build can be restarted.

The failed build can be restarted from the web console by going to the list of builds, selecting on the one which is failing and clicking on _Start Build_.

On the command line, use ``oc get builds`` to determine which build failed, then run ``oc start-build`` on the corresponding build configuration. For example:

```
oc start-build jupyterhub-hub-img --follow
```

The ``--follow`` option is optional, and will result in the build being monitored, with log file output appearing in the terminal.

## Corrupt Database

JupyterHub uses a PostgreSQL database to store the current list of whitelisted users and admin users, along with the state of any current active sessions.

If this database were to become corrupted, the easiest way to recover is to start over with a fresh database. To be able to do this, you need to have ensured you have kept up to date the config maps for the admin users and user whitelist. That is, if you had manually added users, or designated users as admins, through the admin panel of JupyterHub, that you had also updated the corresponding config maps. So long as you do this, the database can be re-created from the lists provided by the config maps.

To facilitate re-creating the database, you should perform the following steps.

First up, if you don't have a copy of the config maps for the admin users and user whitelist saved separate to the OpenShift cluster, make one. This can be done by running the commands:

```
scripts/extract-admin-users.sh coursename > admin_users.txt
```

and

```
scripts/extract-user-whitelist.sh coursename > user_whitelist.txt
```

This is a backup copy just in case required.

Next ensure that both PostgreSQL and JupyterHub are not running. This can be done by running the commands:

```
oc scale --replicas=0 jupyterhub -n coursename
```

and:

```
oc scale --replicas=0 jupyterhub-db -n coursename
```

The ``-n`` argument ensures you are performing the step against the correct project for the course.

Now ensure there are no Jupyter notebook instances running.

```
oc delete pods --selector component=singleuser-server -n coursename
```

From the host where you are able to mount the NFS volumes, run:

```
sudo scripts/create-database-directory.sh coursename 2
```

This should result in a new directory being created with format ``database-$COURSE_NAME-pv2``. That is, it will create a directory parallel to the existing directory for the database, but with ``2`` at the end.

Next create the corresponding persistent volume resource definition.

```
scripts/create-database-volume.sh coursename 2
```

This should result in a persistent volume resource definition with name ``$COURSE_NAME-database-pv2`` being created.

It is now necessary to unmount the existing persistent volume claim from the deployment configuration for the PostgreSQL database.

```
oc set volume dc/jupyterhub-db --remove --name data -n coursename
```

Now create a new persistent volume claim associated with the new persistent volume.

```
oc process -f templates/database-claim.json \
  --param COURSE_NAME=coursename \
  --param VERSION_NUMBER=2 | oc create -f - -n coursename
```

This should result in the creation of a peristent volume claim in the project for the course with format ``jupyterhub-database-pvc2``.

The persistent volume can now be mounted against PostgreSQL using:

```
oc set volume dc/jupyterhub-db --add \
  --claim-name jupyterhub-database-pvc2 --name data \
  --mount-path /var/lib/pgsql/data
```

Set PostgreSQL running again by running:

```
oc scale --replicas=1 jupyterhub-db -n coursename
```

Confirm that PostgreSQL starts up okay.

Then start up JupyterHub again.

```
oc scale --replicas=1 jupyterhub -n coursename
```

## Load Testing

If needing to load test the JupyterHub deployment and OpenShift environment to see if you can create many concurrent Jupyter notebook instances at the same time, you will first need to disable the LDAP authentication mechanism for users.

From the web console, edit the config map ``jupyterhub-cfg`` and under the ``jupyterhub_config.py`` entry add:

```
c.JupyterHub.authenticator_class = 'tmpauthenticator.TmpAuthenticator'
```

Also override the default timeout for idle Jupyter notebook instances so that they will be cleaned up after a shorter period than the default of 60 minutes (3600 seconds).


```
oc set env dc/jupyterhub JUPYTERHUB_IDLE_TIMEOUT=300
```

Running ``oc set env`` will cause a redeployment of JupyterHub and the updated config map will now also be used.

You can now use curl to create Jupyter notebook instances. A script for testing can be found at [scripts/spawn-jupyter-notebooks.sh](../scripts/spawn-jupyter-notebooks.sh).

Run the script as:

```
scripts/spawn-jupyter-notebooks.sh https://... 10 3
```

The arguments are the URL for the JupyterHub instance, the number of sessions to create and the delay between each session being created.
