# Installation Requirements

This example has been tailor made for a specific deployment environment, it will not work out of the box in other environments. The requirements the example imposes are as follows:

* Persistent volumes capable of supporting ``ReadWriteOnce`` and ``ReadWriteMany`` are required. The scripts and templates are set up with expectation that these are provided by an NFS server.
* You have super user access on the host, and are able to mount volumes from the NFS server so necessary sub directories can be created in the volume to match directories specified in the persistent volume resource definitions.
* You have cluster admin access for the OpenShift cluster in order to be able to create the persistent volume resource definitions.
* If a memory quota exists for terminating workloads (source and docker type builds) is being enforced, it must be at least 3GB.

If attempting to customise this example to use on other environments, you will need to adjust these environment specific aspects of the scripts and templates.
