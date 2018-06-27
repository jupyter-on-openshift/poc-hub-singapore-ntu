#!/bin/bash

# Template pv-template-volume-jupyterhub-notebooks is available globally

if [ "$? -ge 1 ];then
   COURSE=$1
   shift
else
   read -p "COURSE NAME: " COURSE
NOTEBOOKS_PATH=/NTU/SPMS/openshift/jupyter/notebooks-$COURSE
oc process openshift//pv-template-volume-jupyterhub-notebooks \
   -v COURSE_NAME=$COURSE \
   -v NFS_PV_NOTEBOOKS_PATH=$NOTEBOOKS_PATH \
   -v NFS_PV_NOTEBOKKS_CAPACITY=25Gi \
   -v NFS_SERVER_NAME=sds.ntu.edu.sg | oc create -f -


