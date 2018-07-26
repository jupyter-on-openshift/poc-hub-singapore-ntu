# Shutdown the Environment

The JupyterHub instance would normally be left running for the entire time it is required. If however it is necessary to temporarily shutdown the environment so it is not accessible, without deleting the environment, it can be done by scaling down the JupyterHub instance, along with the database.

## Shutting Down JupyterHub

To shutdown the JupyterHub instance, without deleting the environment, you can use the ``oc scale`` command.

```
$ oc scale dc jupyterhub --replicas=0 -n coursename
deploymentconfig "jupyterhub" scaled
```

This will shutdown just the JupyterHub instance, making all Jupyter notebooks inaccessible. Jupyter notebook instances still running when JupyterHub is shutdown, may continue to run.

To startup the JupyterHub instance again, run:

```
$ oc scale dc jupyterhub --replicas=1 -n coursename
deploymentconfig "jupyterhub" scaled
```

Do not ever set the number of replicas of JupyterHub to any value besides 0 or 1. This is because some information about active user sessions is kept in memory and scaling up to more than 1 replica can result in Jupyter notebook instances being inaccessible for users.

When the JupyterHub instance is restarted in this way, if there were any Jupyter notebook instances running, users will once again be able to access the existing instance. If however, the JupyterHub instance had been shutdown for longer that the culling interval for idle Jupyter notebook instances, any Jupyter notebook instances will be shutdown when JupyterHub starts up again.

## Shutting Down Jupyter Notebooks

If when shutting down JupyterHub, you want to also shutdown all Jupyter notebook instances first, then this can be done from the admin panel accessed from the control panel in JupyterHub. Select the _Stop All_ button in the admin panel. Once shutdown of all the Jupyter notebook instances has been done, you can then shutdown the JupyterHub instance.

If you need to shutdown a specific Jupyter notebook instance, and JupyterHub is running, this also can be done from the admin panel by selecting _stop server_ for the user.

The preferred way of shutting down Jupyter notebook instances is from the admin panel of JupyterHub. This ensures that JupyterHub can track the current state of the Jupyter notebook instance for a user. If Jupyter notebook instances need to be shutdown quickly, or JupyterHub is not accessible, they can be killed using the ``oc delete pod`` command.

To get a list of all running pods corresponding to Jupyter notebooks instance you can run:

```
$ oc get pods -n coursename --selector app=jupyterhub,component=singleuser-server
```

You can kill the Jupyter notebook instance for a specific user by identifying the pod for that user. The name of the pod will contain the user login name. You can delete it using ``oc delete pod``.

```
$ oc delete pod jupyterhub-nb-username -n coursename
pod "jupyterhub-nb-username" deleted
```

To kill all Jupyter notebook instances at the same time, run:

```
$ oc delete pods -n coursename --selector app=jupyterhub,component=singleuser-server
```

When a Jupyter notebook is shutdown, when a user accesses JupyterHub again, a new Jupyter notebook instance will be automatically started up for them. If they see an error message, they may have to select on _Home_ and then click on _My Server_ to start the new Jupyter notebook instance.

## Shutting Down the Database

If the JupyterHub instance has been shutdown, and you want to also shutdown the PostgreSQL database, you can run:

```
$ oc scale dc jupyterhub-database --replicas=0 -n coursename
deploymentconfig "jupyterhub-database" scaled
```

To start up the PostgreSQL database again, you can run:

```
$ oc scale dc jupyterhub-database --replicas=1 -n coursename
deploymentconfig "jupyterhub-database" scaled
```

Do not ever set the number of replicas of PostgreSQL to any value besides 0 or 1. If you scale up the number of replicas for PostrgreSQL to more than 1, you can corrupt the database.

It is recommended that the PostgreSQL instance be started up before starting up JupyterHub, if both had been shutdown. This will avoid issues with JupyterHub not starting up and failing the deployment due to the PostgreSQL database not being available.

## Restarting the Environment

If at any time you want to restart the JupyterHub instance, possibly because of a failed deployment due to the PostgreSQL database not being available, you can use:

```
$ oc rollout latest jupyterhub -n coursename
deploymentconfig "jupyterhub" rolled out
```

You can monitor the progress of the restart by running:

```
$ oc rollout status dc/jupyterhub -n coursename
replication controller "jupyterhub-1" successfully rolled out
```
