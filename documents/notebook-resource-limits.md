# Notebook Resource Limits

Notebooks created for users have default resource limits applied for both memory and CPU.

The default limit on memory which can be used by each Jupyter notebook instance is 512Mi.

The default limit on CPU which can be used by each Jupyter notebook instance is 1 CPU core.

In addition to the limit on the maximum resources that can be used, by a user for the Jupyter notebook instance, there is a minimum guaranteed reservation of resources that each user will get.

The default request on memory is 409Mi. The default request on CPU is 0.1 CPU core.

The request values are what OpenShift uses to work out which node is best to run a new Jupyter notebook instance. OpenShift will only schedule an application to a node where there is sufficient resources still remaining to satisfy the request.

Even though this value is requested, the application may not use that amount. If the application does use more resources, it will still be capped at the limit value.


If a node becomes overloaded and free memory becomes low, OpenShift may shutdown Jupyter notebooks which are using more memory than their request value. In this case the user would need to restart their Jupyter notebook instance.

In the case of available CPU becoming low, Jupyter notebook instances will be throttled in ratio with other users.

When a Jupyter notebook instance is started, its memory usage will be minimal. More memory will be used each time a separate Jupyter notebook file is opened and used. Users should only open notebook files they are intending to use. If they open too many notebook files, they can reach the limit on memory and actions could start failing. In this case, users should shutdown running processes for notebooks from the Jupyter notebook web interface.

If there is a valid need to increase the limit on memory available to a user for the Jupyter notebook instance, it can be modified after the JupyterHub deployment has been created, by overriding the environment variable settings in the deployment configuration for the JupyterHub instance.

To see the current memory request and limit values for a JupyterHub instance, you can run:

```
$ oc set env dc/jupyterhub --list -n coursename | grep NOTEBOOK_MEMORY
NOTEBOOK_MEMORY_REQUEST=409Mi
NOTEBOOK_MEMORY_LIMIT=512Mi
```

To see the current CPU request and limit values for a JupyterHub instance, you can run:

```
$ oc set env dc/jupyterhub --list -n coursename | grep NOTEBOOK_CPU
NOTEBOOK_CPU_REQUEST=0.1
NOTEBOOK_CPU_LIMIT=1.0
```

To increase the memory limit value, you can run:

```
$ oc set env dc/jupyterhub NOTEBOOK_MEMORY_LIMIT=1Gi -n coursename
deploymentconfig "jupyterhub" updated
```

You can supply bytes, or values with Mi or Gi units for memory.

For CPU, it should be a float value, where ``1.0`` represents one CPU core.

In general, only the limit on memory may need to be adjusted. This should only be adjusted after taking into consideration the overall memory available on application nodes (less some amount for control plane overhead, and JupyterHub and PostgreSQL database instances) and the number of expected JupyterHub instances.

When the value is updated using ``oc set env``, the JupyterHub instance will be automatically re-deployed. The new value will take affect for newly created Jupyter notebook instances. Existing Jupyter notebook instances would need to be restarted to inherit the new values.
