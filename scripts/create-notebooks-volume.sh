#!/bin/bash

# Assumed that a project is used for each course and the name of the
# course is used for the project name. Inside of the project, it is
# assumed that the JupyterHub deployment is called 'jupyterhub'.

JUPYTERHUB_DEPLOYMENT=${JUPYTERHUB_DEPLOYMENT:-jupyterhub}

# Script can optionally be passed the course name. If not supplied the
# user will be prompted to supply it.

if [ "$#" -ge 1 ]; then
    COURSE_NAME=$1
    shift
else
    read -p "Course Name: " COURSE_NAME
fi

read -p "Continue? [Y/n] " DO_UPDATE

if ! [[ $DO_UPDATE =~ ^[Yy]$ ]]; then
    exit 1
fi

# Assumed that 'oc' is in the current path and that the script is being
# run with appropriate privileges to perform update on cluster wide
# resources. First check that a persistent volume doesn't already exist
# with the name we intend using.

PERSISTENT_VOLUME_NAME=$COURSE_NAME-notebooks-pv

oc get "pv/$PERSISTENT_VOLUME_NAME" > /dev/null 2>&1

if [ "$?" == "0" ]; then
    echo "ERROR: Persistent volume for $COURSE_NAME notebooks already exists."
    exit 1
fi

# Now create the persistent volume. The persistent volume will have a
# claim pre-binding so can only be used by the specific course for
# notebooks. The reclaim policy will be retain, which means when any
# persistent volume clean is deleted, the persistent volume will need to
# be cleaned up manually.
#
# Note that the template doesn't needed to be loaded into the OpenShift
# cluster, it will be used from the file system where the script exists.

oc process -f `dirname $0`/template-notebooks-volume.json \
    --param COURSE_NAME=$COURSE_NAME \
    --param APPLICATION_NAME=$JUPYTERHUB_DEPLOYMENT | \
    oc create -f -

if [ "$?" != "0" ]; then
    echo "ERROR: Failed to create persistent volume for $COURSE_NAME notebooks."
    exit 1
fi
