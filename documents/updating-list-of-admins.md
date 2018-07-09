# Updating List of Admins

JupyterHub provides a means for users to create their own Jupyter notebook instance. With the configuration for this example, each normal user can only see their own workspace and their own copy of the notebooks for a course.

Any user of the JupyterHub instance can optionally be designated as an admin of the JupyterHub instance. This will give them additional capabilities for the JupyterHub instance. Being an admin in the JupyterHub instance is completely unrelated to the underlying OpenShift environment, and does not grant any access to OpenShift (if not already a user in OpenShift), or extra capabilities in the OpenShift cluster (if an existing normal user in OpenShift).

With the configuration used for this example, the extra capabilities that a user marked as an admin in JupyterHub has are:

* When they start up their Jupyter notebook instance, they will startup in their own workspace, but they can traverse back up the directory hierarchy through the web interface and are able to see the workspaces of all other users using the JupyterHub instance.
* From the control panel for JupyterHub, they can access the admin panel. The admin panel allows them to see what users are registered, and whether they have an active Jupyter notebook instance. They can stop or start a users Jupyter notebook instance. They can access another users Jupyter notebook instance and work in it as if they were that user. They can also add or delete users from the admin panel, or mark a user as an admin in JupyterHub.

When the JupyterHub instance is initially deployed, a list of initial admin users can be specified. This list is added to what is called a config map in OpenShift. This config map is in turn mounted as a file into the JupyterHub instance and is used to populate the JupyterHub database.

## Querying Admin Users

To get a copy of the current contents of the config map used to initialise JupyterHub, run the script:

```
$ scripts/extract-admin-users.sh coursename > coursename-admin_users.txt
```

The contents of the config map will displayed as output, so can be saved to a file by directing output to a file as shown.


## Adding Admin Users

Although new admin users can be added through the admin panel in JupyterHub, those additions will not be reflected in the config map. It is therefore recommended that the list of admin users be added by updating the config map instead. If an admin user were added through the admin panel of JupyterHub, you should go back and also add them to the config map so you have it as a full record of current list of admin users.

To add a new admin user in the config map, edit the ``coursename-admin_users.txt`` file created when you queried the current contents of the config map.

This file will contain a list of the LDAP usernames for those designated as admin users. Each name will be separated by whitespace. They may therefore be listed on one line with spaces between them, or on separate lines.

Add the LDAP username of the new admin user to the file.

To update the config map, run the script:

```
$ scripts/update-admin-users.sh coursename coursename-admin_users.txt
```

If you don't supply the arguments, you will be prompted for the inputs.

You will also be asked whether you want to trigger a new deployment of JupyterHub. This will cause JupyterHub to be restarted so that the updated config map is read.

## Removing Admin Users

To remove a user as an admin requires two steps. You first need to remove the user from the config map for the admin users. This is done using the same process as adding an admin user, except that you are removing the LDAP username from the file containing the list of admin users, before updating the config map with the modified file.

A second step that must then be done, is to also remove the user as an admin from the admin panel in JupyterHub. If you do not do this, the user will still be recorded as an admin in the JupyterHub database. This is because JupyterHub doesn't synchronise the database with the list from the config map when entries are removed.

When removing the user as an admin from the JupyterHub admin panel you have two options.

The first option is to edit the entry for the user in the admin panel, and remove their admin rights. If this is done, the user will still exist in JupyterHub, but they will not have the admin rights. Note though that because the user will continue to exist, they can still access their Jupyter notebook instance as if they were a normal user, even if they aren't listed as a user in the user whitelist. It is better to remove them completely as described below if they should not retain any access.

The second option is to delete the user completely from the JupyterHub admin panel. This will remove them from the JupyterHub database and they will not be able to use the JupyterHub instance. Note though that if the user is also listed in the user whitelist still, they will be added back into the JupyerHub database the next time the JupyterHub instance is restarted. Ensure therefore that the user is also removed from the user whitelist if they appeared in both the user whitelist and list of admin users, and they should not retain any access.

## Admin Users Backups

If the list of admin users stored in the config map has not been kept in synchronisation with what is in the database, it is possible to retrieve an up to date copy from the JupyterHub instance. This is done by retrieving it from backups which are periodically made from the database.

To see the list of files in the backups directory, first identify the name of the pod for the JupyterHub instance using ``oc get pods``.

```
$ oc get pods -n coursename --selector app=jupyterhub,deploymentconfig=jupyterhub
NAME                  READY     STATUS    RESTARTS   AGE
jupyterhub-40-pgm8w   1/1       Running   0          3d
```

Once you have the name of the pod, you can list what backup files there are by running ``oc rsh``.

```
$ oc rsh -n coursename podname ls /opt/app-root/notebooks/backups
admin_users-2018-07-09-01-45-16.txt
user_whitelist-2018-07-09-01-45-16.txt
```

The suffix of the files is of the form ``-YYYY-MM-DD-hh-mm-ss.txt``.

Find the most recent copy of the ``admin_users`` file. To copy the file back to the current host, run ``cat`` on the file and save the results to a file.

```
$ oc rsh -n coursename podname  \
  cat /opt/app-root/notebooks/backups/admin_users-2018-07-09-01-45-16.txt >
  coursename-admin_users.txt
```

A new backup file is created each time the JupyterHub instance is restarted. A backup will also be periodically made if it is detected that a change was made to the list of admin users since the last time a backup was made.

You can therefore use the backup files as an audit trail as to when changes were made to the list of admin users.
