#!/bin/bash

# Assumed that a project is used for each course and the name of the
# course is used for the project name. Inside of the project, it is
# assumed that the JupyterHub deployment is called 'jupyterhub' and that
# the admin users is maintained under the key 'admin_user.txt' in
# the config map with name 'jupyterhub-cfg'.

JUPYTERHUB_DEPLOYMENT=${JUPYTERHUB_DEPLOYMENT:-jupyterhub}
ADMIN_USERS_CONFIG_MAP=${JUPYTERHUB_DEPLOYMENT}-cfg
ADMIN_USERS_CONFIG_MAP_KEY=admin_users.txt

# Script must be passed the course name as argument.

if [ "$#" -ne 1 ]; then
    echo "USAGE: `basename $0` course-name" 1>&2
    exit 1
fi

COURSE_NAME=$1

# Assumed that 'oc' is in the current path and that the script is being
# run with appropriate privileges to perform update on project. First
# check that we can find the deployment in the project and then a config
# map.

oc get "dc/$JUPYTERHUB_DEPLOYMENT" -n "$COURSE_NAME" > /dev/null 2>&1

if [ "$?" != "0" ]; then
    echo "ERROR: Cannot find JupyterHub deployment for $COURSE_NAME." 2>&1
    exit 1
fi

oc get "configmap/$ADMIN_USERS_CONFIG_MAP" -n "$COURSE_NAME" > /dev/null 2>&1

if [ "$?" != "0" ]; then
    echo "ERROR: Cannot find config map for $COURSE_NAME." 1>&2
    exit 1
fi

# 

oc get "configmap/$ADMIN_USERS_CONFIG_MAP" -o go-template --template \
    "{{ (index .data \"$ADMIN_USERS_CONFIG_MAP_KEY\") }}" \
    -n "$COURSE_NAME"

if [ "$?" != "0" ]; then
    echo "ERROR: Cannot extract admin users from $COURSE_NAME." 1>&2
    exit 1
fi
