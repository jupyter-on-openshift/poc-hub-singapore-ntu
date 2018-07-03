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
