# Forking the repository

This example has been tailor made for a specific deployment environment, it will not work out of the box in other environments. You should create a copy or fork of this repository before you use it. This will allow you to modify it to customise it to your own requirements.

After you have created the copy or fork, you will need to modify the following files so that references to the original repository are changed, and replaced with references to your repository.

* [templates/jupyterhub.json](../templates/jupyterhub.json) - Find all occurrences of ``jupyter-on-openshift/poc-hub-singapore-ntu.git`` and change it to refer to the name of your account and repository. If you are not using GitHub, also change ``github.com`` in the same line to be the hostname for the Git repository hosting service you are using.

The ``templates/jupyterhub.json`` file also contains references to ``jupyter-on-openshift/jupyter-notebooks.git`` and ``jupyter-on-openshift/jupyterhub-quickstart.git``. These refer to separate repositories containing the core code used to build the Jupyter notebook and JupyterHub base images. You do not need to change these references unless you are also making a copy or forking those repositories so you can customise them. In normal use you should never need to modify those two repositories. Instead customisations for those are layered on top using S2I or docker build processes.
