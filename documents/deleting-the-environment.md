# Deleting the Environment

When a JupyterHub instance is no longer required, it will need to be deleted.

To delete the JupyterHub instance, the database and all user files, involves the following steps.

* Delete the project for the JupyterHub instance.
* Delete the persistent volume definitions.
* Delete the directories in NFS storage.

## Deleting the Project

The scripts provided for deploying the JupyterHub instance always use a new project for a JupyterHub instance. The intention is that the only application deployed to the project is the JupyterHub instance.

On the basis that the JupyterHub instance is the only application in a project, to delete the JupyterHub instance, you can delete the project. This is done using the ``oc delete project`` command.

```
$ oc delete project coursename
project "coursename" deleted
```

Because the entire project containing the JupyterHub instance is deleted, the secrets, config maps, service accounts and persistent volume claims created for the JupyterHub instance will also be deleted.

## Deleting the Persistent Volume

Although the persistent volume claims in the project for a JupyterHub instance will be deleted when the project is deleted, the underlying persistent volume resource definition, corresponding to the persistent volume claim, will not be deleted.

Further, because the persistent volume resource definition is marked as ``Retain``, and was also setup with a claim ref for the specific JupyterHub instance, it cannot be reused. This ensures that the data held in the underlying storage, is not inadvertently used by a new JupyterHub deployment.

To delete the persistent volume resource definitions, you need to run ``oc delete pv`` as a cluster admin for each persistent volume resource definition, supplying the names of the persistent volumes.

```
$ oc delete pv coursename-notebooks-pv
persistentvolume "coursename-notebooks-pv" deleted

$ oc delete pv coursename-database-pv
persistentvolume "coursename-database-pv" deleted
```

Deleting the persistent volume resource definition will not delete the directory from NFS storage.

## Deleting the NFS Storage

Although a JupyterHub instance has been deleted, along with the persistent volume resource definitions, you may wish to retain the database and user files in NFS storage, and only delete them at a later time when you are sure they are no longer required.

To delete the database and notebooks directories from NFS storage, you will need to mount the respective NFS storage shares, and delete the corresponding directories.

The directories which will need to be deleted are:

* ``notebooks-coursename-pv``
* ``database-coursename-pv``
