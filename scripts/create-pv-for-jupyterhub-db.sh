#!/bin/bash
# Template pv-template-volume-jupyterhub-database is available globally

if [ "$? -ge 1 ];then
   COURSE=$1
   shift
else 
   read -p "COURSE NAME: " COURSE
DB_PATH=/NTU/SPMS/openshift/jupyterhubdb/database-$COURSE
oc process openshift//pv-template-volume-jupyterhub-database \
   -v COURSE_NAME=$COURSE \
   -v NFS_PV_DB_PATH=$DB_PATH \
   -v NFS_PV_DB_CAPACITY=1Gi \
   -v NFS_SERVER_NAME=sds.ntu.edu.sg | oc create -f -
