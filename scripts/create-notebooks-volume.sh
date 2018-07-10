#!/bin/bash

NFS_SERVER_NAME=${NFS_SERVER_NAME:-sds.ntu.edu.sg}
NFS_SERVER_SHARE=${NFS_SERVER_SHARE:-/NTU/SPMS/openshift/jupyter}

# Assumed that a project is used for each course and the name of the
# course is used for the project name. Inside of the project, it is
# assumed that the JupyterHub deployment is called 'jupyterhub'.

JUPYTERHUB_DEPLOYMENT=${JUPYTERHUB_DEPLOYMENT:-jupyterhub}

# Script can optionally be passed the course name and a version number.
# If not supplied the user will be prompted to supply them. There is no
# strict need for the version number, which is more relevant to the
# database volume, but support it just in case there is a reason to
# start over with storage for notebooks.

if [ "$#" -ge 1 ]; then
    COURSE_NAME=$1
    shift
else
    read -p "Course Name: " COURSE_NAME
fi

COURSE_NAME=`echo $COURSE_NAME | tr 'A-Z' 'a-z'`

if ! [[ $COURSE_NAME =~ ^[a-z0-9-]*$ ]]; then
    echo "ERROR: Invalid course name $COURSE_NAME."
    exit 1
fi

if [ "$#" -ge 1 ]; then
    VERSION_NUMBER=$1
    shift
else
    read -p "Version Number: " VERSION_NUMBER
fi

if [ x"$CONTINUE_PROMPT" != x"n" ]; then
    read -p "Continue? [Y/n] " DO_UPDATE
fi

if ! [[ $DO_UPDATE =~ ^[Yy]?$ ]]; then
    exit 1
fi

# Assumed that 'oc' is in the current path and that the script is being
# run with appropriate privileges to perform update on cluster wide
# resources. First check that a persistent volume doesn't already exist
# with the name we intend using.

PERSISTENT_VOLUME_NAME=$COURSE_NAME-notebooks-pv$VERSION_NUMBER

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

oc process -n default \
    -f `dirname $0`/../templates/notebooks-volume.json \
    --param COURSE_NAME=$COURSE_NAME \
    --param VERSION_NUMBER=$VERSION_NUMBER \
    --param APPLICATION_NAME=$JUPYTERHUB_DEPLOYMENT \
    --param NFS_SERVER_NAME=$NFS_SERVER_NAME \
    --param NFS_SERVER_SHARE=$NFS_SERVER_SHARE | \
    oc create -n default -f -

if [ "$?" != "0" ]; then
    echo "ERROR: Failed to create persistent volume for $COURSE_NAME notebooks."
    exit 1
fi
