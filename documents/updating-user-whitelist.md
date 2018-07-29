# Updating User Whitelist

JupyterHub provides a means for users to create their own Jupyter notebook instance. Only users who can login in with the configured authentication provider, and who are listed as a user in the JupyterHub database can use JupyterHub to create a Jupyter notebook.


## Initial Setup of Users

Note that when JupyterHub is initially deployed, the list of normal users will be empty. In this state, where no users are listed in the database, JupyterHub will allow any authenticated user to create Jupyter notebook instances. If you need to restrict the set of users who can create Jupyter notebooks, you must add at least one normal user. This requirement is independent of whether any admin users have been declared.

JupyterHub provides two ways of adding users. If the set of users is going to be fixed and doesn't need to be changed over time, you can load the list of users through a config map and restart JupyterHub. This will cause that list of users to be added to the JupyterHub database.

If the set of users may need to change, you should not use the config map method of loading the users, and leave the config map empty. Instead, you should load users directly into the JupyterHub database. This can be done by a user designated as an admin, through the admin panel of JupyterHub, or the JupyterHub REST API can be used.

The reason for updating the JupyterHub database directly when changes need to be made is that, if a user is included in the list held by the config map, and the user is deleted via the admin panel, when JupyterHub is restarted, the user will be added back to the JupyterHub database again from the config map. To avoid this you would need to manually keep the list in the config map synchronised with the database, and remove the user from that list as well as removing them via the admin panel.

## Adding Users via the REST API

Users can be added direct to the JupyterHub database using the scripts:

* [scripts/add-user-to-jupyterhub.sh](../scripts/add-user-to-jupyterhub.sh) - Adds a single user to the JupyterHub user database via the REST API.
* [scripts/add-multiple-users-to-jupyterhub.sh](../scripts/add-multiple-users-to-jupyterhub.sh) - Adds multiple users to the JupyterHub user database via the REST API.

To add a single user use the command:

```
$ scripts/add-user-to-jupyterhub.sh coursename username
[{"kind": "user", "name": "username", "admin": false, "groups": [], "server": null, "pending": null, "created": "2018-07-27T00:55:50.163763Z", "last_activity": null, "servers": null}]
```

The script will output a record as JSON for the user which was added. If the user already exists, you will get an error response:

```
{"status": 409, "message": "User username already exists"}
```

To add multiple users in one command, create an input file with a list of the users one per line. Then run the command:

```
$ ./scripts/add-multiple-users-to-jupyterhub.sh coursename users.txt
[{"kind": "user", "name": "username1", "admin": false, "groups": [], "server": null, "pending": null, "created": "2018-07-27T00:58:16.451094Z", "last_activity": null, "servers": null}, {"kind": "user", "name": "username2", "admin": false, "groups": [], "server": null, "pending": null, "created": "2018-07-27T00:58:16.453661Z", "last_activity": null, "servers": null}, {"kind": "user", "name": "username3", "admin": false, "groups": [], "server": null, "pending": null, "created": "2018-07-27T00:58:16.456022Z", "last_activity": null, "servers": null}]
```

The script will output the record of all users added. If all users already existed, you will see an error response of:

```
{"status": 409, "message": "All 3 users already exist"}
```

If some users already existed and others didn't, you will only see output the record of which users were added. So it is safe to attempt to add users which are already recorded in the JupyterHub database.

Note that in order to be able to access the JupyterHub REST API, an access token is needed. The script obtains this access token by accessing a pre-generated token from the deployment config for JupyterHub in OpenShift. You therefore need to be logged into OpenShift from the command line with an account with appropriate access to the project for the course.

## Removing Users via the REST API

A user can be removed direct from the JupyterHub database using the script:

* [scripts/remove-user-from-jupyterhub.sh](../scripts/remove-user-from-jupyterhub.sh) - Removes a single user from the JupyterHub user database via the REST API.

This can be used to remove any users, including users designated as admins.

To remove a single user use the command:

```
$ ./scripts/remove-user-from-jupyterhub.sh coursename username
```

Output will be empty if it succeeds. If you attempt to remove a user that doesn't exist, you will see the response:

```
{"status": 404, "message": "Not Found"}
```

The REST API doesn't provide a way to remove users in bulk. They would need to be remove one at a time.

When a user is removed, any Jupyter notebook instance they currently have running will be shutdown.

Note that if you remove a user in this way who was originally added using the user whitelist config map, they will be added back again the next time JupyterHub is restarted, unless you also update the config map.

## Using the JupyterHub Admin Panel

To add users via the admin panel, you need to be logged in as a user designated as an admin in JupyterHub. You should access the _Control Panel_ and then the _Admin_ panel.

From the admin panel, select on _Add Users_. From the popup window, you can add a new user. If you need to add more than one user, they need to be listed one per line. You cannot list multiple users on the same line.

To delete a user, find the user in the list of users from the admin panel and select _delete_. If the user has a current Jupyter notebook instance, that Jupyter notebook instance will be shutdown, when removing the user from the database.

Note that if you remove a user in this way who was originally added using the user whitelist config map, they will be added back again the next time JupyterHub is restarted, unless you also update the config map.

## Querying User Whitelist Config Map

If using the config map to load users, to get a copy of the current contents of the config map for the JupyterHub instance, you can run the script:

```
$ scripts/extract-user-whitelist.sh coursename > coursename-user_whitelist.txt
```

The contents of the config map will be displayed as output, so can be saved to a file by directing output to a file as shown.

Note that this list is not what is recorded in the JupyterHub database. Any users added through the admin panel of JupyterHub will not be in this list, unless they were also added to it as a separate manual step.

If you want to see the full list of users in the JupyterHub database, use the admin panel, or access the backup files created from the database.

## Updating User Whitelist Config Map

If not using the recommended method of adding users via the admin panel of JupyterHub or using the REST API, and you want to load them via the config map, create a file which contains the LDAP usernames of the users. Add the users one per line.

To update the config map, run the script:

```
$ scripts/update-user_whitelist.sh coursename coursename-user_whitelist.txt
```

The arguments are the name of the course and the file containing the list of users. If you don't supply the arguments, you will be prompted for the inputs.

You will also be asked whether you want to trigger a new deployment of JupyterHub. This will cause JupyterHub to be restarted so that the updated config map is read.

When JupyterHub is restarted, any new users listed in the config map, will be added to the JupyterHub database, and those users will now be able to create a Jupyter notebook instance, so long as they can also login.

If you are using the config map to load the users, and need to remove a user, two steps are required.

You first need to remove the user from the config map for the user whitelist. This is done using the same process as adding a user, except that you are removing the LDAP username from the file containing the user whitelist, before updating the config map with the modified file.

A second step that must then be done, is to also delete the user from the admin panel in JupyterHub. If you do not do this, the user will still be recorded in the JupyterHub database. This is because JupyterHub doesn't synchronise the database with the list from the config map when entries are removed.

Performing the second step of deleting the user from the admin panel will remove them from the JupyterHub database and they will not be able to use the JupyterHub instance. Note though that if the user was also listed in the config map for admin users, they will be added back into the JupyterHub database the next time the JupyterHub instance is restarted. Ensure therefore that the user is also removed from the admin users if they appeared in both the user whitelist and list of admin users, and they should not retain any access.

Because of the need to perform two steps when removing users, if you know you will need to keep making changes, it is better to load users and make changes through the admin panel and not use the config map.

## User Whitelist Database Backups

As the recommended procedure is to use the admin page in JupyterHub, or the REST API, to manage users directly in the JupyterHub database, the user whitelist in the config map will usually be empty. In this case it is possible to retrieve a backup with the contents of the JupyterHub user database.

There are two ways that the user database is backed up, which you can retrieve. The need to backup the database is checked on a five minute interval. The backup will only be done if a change in the users is detected.

The first type of backup is done to a config map in OpenShift. To retrieve this backup for users you can use the script:

* [scripts/extract-user-whitelist-backup.sh](../scripts/extract-user-whitelist-backup.sh) - Download the backup of the users in the JupyterHub database.

Run the script as:

```
$ scripts/extract-user-whitelist-backup.sh coursename > coursename-user_whitelist.txt
```

The file created will only include normal users. It will not include users who are marked as an admin.

This type of backup only provides the latest set of users from the JupyterHub database.

A second type of backup is done by writing the backup files to the same persistent volume as is used for notebooks.

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
admin_users-latest.txt
user_whitelist-latest.txt
```

The suffix of the timestamped files is of the form ``-YYYY-MM-DD-hh-mm-ss.txt``. There is also one with the ``-latest.txt`` extension which is a symlink to the latest timestamped file.

To copy a file back to the current host, run ``cat`` on the file and save the results to a file.

```
$ oc rsh -n coursename podname \
  cat /opt/app-root/notebooks/backups/user_whitelist-2018-07-09-01-45-16.txt >
  coursename-user_whitelist.txt
```

A new backup file is created each time the JupyterHub instance is restarted. A backup will also be periodically made if it is detected that a change was made to the list of users in the whitelist since the last time a backup was made.

You can therefore use the backup files as an audit trail as to when changes were made to the list of users in the whitelist.

Note that these files are saved into a ``backups`` directory within the persistent volume used to hold users notebooks. An alternative way to retrieve these files is to mount the NFS share for the notebooks directory, and traverse to the ``backups`` directory within the notebooks directory for the course.

## Reconciling the User Whitelist

Users would initially be loaded direct into the JupyterHub user database using the ``add-multiple-users-to-jupyterhub.sh`` script, from a file with a list of the users. You can then, after a backup has been made, retrieve the current contents of the user database.

If you have also added or removed users via the JupyterHub admin panel, the list of the users in the JupyterHub user database, can end up being different to the list you originally loaded. To determine the differences and use that to reconcile expected lists of users and what is in the database, you can use the UNIX utility ``comm``.

As an example, if the original list of users you used was ``original-user_whitelist.txt`` and you can fetched back a copy of users in the user database using ``extract-user-whitelist-backup.sh`` which was called ``current-user_whitelist.txt``, you can compare them by first running the commands:

```
$ sort -u original-user_whitelist.txt > sorted-original-user_whitelist.txt
$ sort -u current-user_whitelist.txt > sorted-current-user_whitelist.txt
```

This will order the list of users and eliminate duplicates.

Then run the ``comm`` command to compare them.

```
$ comm sorted-original-user_whitelist.txt sorted-current-user_whitelist.txt
username1
                    username2
                    username3
                    username4
          username5
```

Column 1 is any users in the first file but not in the second.

Column 2 in any users in the second file but not in the first.

Column 3 is the users in both files.

When running ``comm`` you can be selective as to which set is output by suppressing which columns are shown.

If the original list was the authoritative list, to work out which users are missing from the JupyterHub database, run:

```
$ comm -23 sorted-original-user_whitelist.txt sorted-current-user_whitelist.txt
username1
```

You could save the output from this to a file and then use the ``add-multiple-users-to-jupyterhub.sh`` script to add them.

To work out which users exist in the JupyterHub database which shouldn't be there and which should be removed, you can run:

```
$ comm -13 sorted-original-user_whitelist.txt sorted-current-user_whitelist.txt
username5
```

You could then remove each of these users from the JupyterHub database.
