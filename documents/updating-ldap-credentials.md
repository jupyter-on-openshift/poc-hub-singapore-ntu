# Updating LDAP Credentials

When JupyterHub is being initially deployed, the credentials for the LDAP user to use for looking up user details needs to be provided. If the login credentials needs to be changed during the life of a JupyterHub instance, it is necessary to update the secret in OpenShift which contains the credentials and restart the JupyterHub instance.

The LDAP credentials for a single JupyterHub instance can be updated using the script:

* [scripts/update-ldap-credentials.sh][../scripts/update-ldap-credentials.sh]

This script needs to be supplied three inputs:

* ``Course Name`` - The name identifying the course. This must consist of only lower case letters, numbers, and the dash character. This will be used as the project name and will also appear in the generated hostname for the JupyterHub instance.
* ``LDAP Search User`` - The name of the LDAP user account used to perform searches against the LDAP authentication servers.
* ``LDAP Search Password`` - The password for the LDAP user account used to perform searches against the LDAP authentication servers.

These course name and LDAP user can be supplied as command line arguments. If not supplied as command line arguments, the script will prompt for the values. The LDAP password cannot be supplied via a command line argument and you will always be prompted for it. You will also be prompted as to whether you want to re-deploy the JupyterHub instance straight away.

```
$ scripts/update-ldap-credentials.sh
Course Name: jakevdp
LDAP Search User: ldap-username
LDAP Search Password:
New Deployment? [Y/n] y
Continue? [Y/n] y
secret "jupyterhub-ldap" updated
deploymentconfig "jupyterhub" rolled out
```

If you have multiple JupyterHub instances deploy at the same time and need to update all of them, you can use the script:

* [update-all-ldap-credentials.sh](../update-all-ldap-credentials.sh)

This script needs to be supplied two inputs:

* ``LDAP Search User`` - The name of the LDAP user account used to perform searches against the LDAP authentication servers.
* ``LDAP Search Password`` - The password for the LDAP user account used to perform searches against the LDAP authentication servers.

These LDAP user can be supplied as a command line argument. If not supplied as a command line argument, the script will prompt for the value. The LDAP password cannot be supplied via a command line argument and you will always be prompted for it. You will also be prompted as to whether you want to re-deploy the JupyterHub instance straight away.

```
$ scripts/update-all-ldap-credentials.sh
LDAP Search User: ldap-username
LDAP Search Password:
New Deployment? [Y/n] y
Continue? [Y/n] y
secret "jupyterhub-ldap" updated
deploymentconfig "jupyterhub" rolled out
```
