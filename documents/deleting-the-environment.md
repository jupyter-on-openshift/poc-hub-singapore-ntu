# Deleting the Environment

When a JupyterHub instance is no longer required, it will need to be deleted.

To delete the JupyterHub instance, the database and all user files, involves the following steps.

* Delete the project for the JupyterHub instance.
* Delete the persistent volume definitions.
* Delete the directories in NFS storage.

## Deleting the Project

The scripts provided for deploying the JupyterHub instance always use a new project for a JupyterHub instance. The intention is that the only application deployed to the project is the JupyterHub instance.

On the basis that the JupyterHub instance is the only application in a project, to delete the JupyterHub instance, you can delete the project. This is done using the script:

* [scripts/delete-project.sh](../scripts/delete-project.sh)

This script needs to be supplied a single input:

* ``Course Name`` - The name identifying the course. This must consist of only lower case letters, numbers, and the dash character.

The input can be supplied as a command line argument. If not supplied as  a command line argument, the script will prompt for the value.

Because the entire project containing the JupyterHub instance is deleted, the secrets, config maps, service accounts and persistent volume claims created for the JupyterHub instance will also be deleted.

## Deleting the Persistent Volume

Although the persistent volume claims in the project for a JupyterHub instance will be deleted when the project is deleted, the underlying persistent volume resource definition, corresponding to the persistent volume claim, will not be deleted.

Further, because the persistent volume resource definition is marked as ``Retain``, and was also setup with a claim ref for the specific JupyterHub instance, it cannot be reused. This ensures that the data held in the underlying storage, is not inadvertently used by a new JupyterHub deployment.

To delete the persistent volume resource definitions, you can use the script:

* [scripts/delete-volumes.sh](../scripts/delete-volumes.sh)

The script must be run as a cluster administrator.

This script needs to be supplied the inputs:

* ``Course Name`` - The name identifying the course. This must consist of only lower case letters, numbers, and the dash character.
* ``Version Number`` - An optional version number or instance count. This should be left empty unless you had created a separate new instances of the volumes for the same course.

Deleting the persistent volume resource definition will not delete the directory from NFS storage.

## Deleting the NFS Storage

Although a JupyterHub instance has been deleted, along with the persistent volume resource definitions, you may wish to retain the database and user files in NFS storage, and only delete them at a later time when you are sure they are no longer required.

To delete the database and notebooks directories from NFS storage, you will need to use the scripts:

* [scripts/delete-database-directory.sh](../scripts/delete-database-directory.sh)
* [scripts/delete-notebooks-directory.sh](../scripts/delete-notebooks-directory.sh)

The scripts need to be run as superuser using ``sudo``.

These scripts need to be supplied the inputs:

* ``Course Name`` - The name identifying the course. This must consist of only lower case letters, numbers, and the dash character.
* ``Version Number`` - An optional version number or instance count. This should be left empty unless you had created a separate new instances of the volumes for the same course.
