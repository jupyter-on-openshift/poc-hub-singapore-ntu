# Updating User Whitelist

JupyterHub provides a means for users to create their own Jupyter notebook instance. With the configuration for this example, the only non admin users who are able to create Jupyter notebook instances are those listed in the user whitelist.

Do be aware though that after initially creating the JupyterHub deployment, the user whitelist will be empty. In this initial state, any user who can authenticate with LDAP will be allowed to create a Jupyter notebook instance. This is to facilitate initial testing of the deployment. Before making the JupyterHub instance available, you should update the user whitelist to restrict access to just the required set of users.

## Querying User Whitelist

To get a copy of the current contents of the config map which holds the user whitelist for the JupyterHub instance, run the script:

```
$ scripts/extract-user-whitelist.sh coursename > coursename-user_whitelist.txt
```

The contents of the config map will displayed as output, so can be saved to a file by directing output to a file as shown.


## Adding Normal Users

Although new users can be added through the admin panel in JupyterHub, those additions will not be reflected in the config map. It is therefore recommended that the user whitelist be added by updating the config map instead. If a user were added through the admin panel of JupyterHub, you should go back and also add them to the config map so you have it as a full record of current list users in the whitelist.

To add a new user in the config map, edit the ``coursename-user_whitelist.txt`` file created when you queried the current contents of the config map.

This file will contain a list of the LDAP usernames for those users permitted to use the JupyterHub instance. Each name will be separated by whitespace. They may therefore be listed on one line with spaces between them, or on separate lines.

Add the LDAP username of the new user to the file.

To update the config map, run the script:

```
$ scripts/update-user_whitelist.sh coursename coursename-user_whitelist.txt
```

If you don't supply the arguments, you will be prompted for the inputs.

You will also be asked whether you want to trigger a new deployment of JupyterHub. This will cause JupyterHub to be restarted so that the updated config map is read.

## Removing Normal Users

To remove a user requires two steps. You first need to remove the user from the config map for the user whitelist. This is done using the same process as adding a user, except that you are removing the LDAP username from the file containing the user whitelist, before updating the config map with the modified file.

A second step that must then be done, is to also delete the user from the admin panel in JupyterHub. If you do not do this, the user will still be recorded in the JupyterHub database. This is because JupyterHub doesn't synchronise the database with the list from the config map when entries are removed.

Deleting the user from the admin panel will remove them from the JupyterHub database and they will not be able to use the JupyterHub instance. Note though that if the user is still listed in the list of admin users, they will be added back into the JupyerHub database the next time the JupyterHub instance is restarted. Ensure therefore that the user is also removed from the admin users if they appeared in both the user whitelist and list of admin users, and they should not retain any access.

## User Whitelist Backups

If the user whitelist stored in the config map has not been kept in synchronisation with what is in the database, it is possible to retrieve an up to date copy from the JupyterHub instance. This is done by retrieving it from backups which are periodically made from the database.

To see the list of files in the backups directory, first identify the name of the pod for the JupyterHub instance using ``oc get pods``.

```
$ oc get pods -n coursename --selector app=jupyterhub,deploymentconfig=jupyterhub
NAME                  READY     STATUS    RESTARTS   AGE
jupyterhub-40-pgm8w   1/1       Running   0          3d
```

Once you have the name of the pod, you can list what backup files there are by running ``oc rsh``.

```
$ oc rsh -n coursename podname ls /opt/app-root/notebooks/backups
admin_users-2018-07-08-04-01-17.txt
user_whitelist-2018-07-09-01-45-16.txt
```

The suffix of the files is of the form ``-YYYY-MM-DD-hh-mm-ss.txt``.

Find the most recent copy of the ``user_whitelist`` file. To copy the file back to the current host, run ``cat`` on the file and save the results to a file.

```
$ oc rsh -n coursename podname  \
  cat /opt/app-root/notebooks/backups/user_whitelist-2018-07-09-01-45-16.txt >
  coursename-user_whitelist.txt
```

A new backup file is created each time the JupyterHub instance is restarted. A backup will also be periodically made if it is detected that a change was made to the list of users in the whitelist since the last time a backup was made.

You can therefore use the backup files as an audit trail as to when changes were made to the list of users in the whitelist.
