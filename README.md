# JupyterHub - Teaching Environment

This example is a proof of concept developed to show how a JupyterHub environment can be deployed which is suitable for using Jupyter notebooks in a teaching environment. Some of the features the example illustrates are:

* Each student is provided with a workspace backed by persistent storage. This allows the student to save their work and come back to it later, even if their Jupyter notebook instance is shutdown.
* The students workspace can be pre-populated with Jupyter notebook files and data files. The student can delete or rename the workspace and it will be re-created with a copy of the original Jupyter notebooks and data files.
* A student can only see their own workspace. A lecturer (designated in JupyterHub as an admin user), is able to browse the workspaces of all users through their own Jupyter notebook instance. This is in addition to the ability to impersonate a user and run a Jupyter notebook instance, as that user.
* Jupyter notebook instances which have not been used for 60 minutes will be shutdown. A new Jupyter notebook instance will be automatically started up again when they next access JupyterHub.
* Authentication of users (students, lecturers of other admins), is performed against an LDAP server. Through a custom authenticator, users can select the LDAP domain against which they need to authenticate (students, staff, assoc).
* The Jupyter notebook image used, which dictates what Python packages are pre-installed, and what Jupyter notebooks and data files are available, is built in OpenShift for the deployment using the Source-to-Image (S2I) build process. The source for the Jupyter notebooks, and requirements for what Python packages are pre-installed can be in a public hosted Git repository.
* To accomodate having additional system packages installed, a docker type build step is included in the pipeline to allow the base S2I builder to be customised.
* The JupyterLab web interface can be optionally enabled, resulting in support for it being built into the Jupyter notebook image and it being used instead of the Jupyter notebook classic web interface.
* Scripts are provided to simplify the deployment of the JupyterHub environment, as well as update configuration for LDAP credentials, JupyterHub admin user list and general user whitelist.

Because the example has been tailor made for a specific deployment environment, it will not work out of the box in other environments. It should therefore be used as an example only, and a copy taken which should then be customised for your own requirements.
