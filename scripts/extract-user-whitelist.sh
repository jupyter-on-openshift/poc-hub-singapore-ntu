#!/bin/bash

# Assumed that a project is used for each course and the name of the
# course is used for the project name. Inside of the project, it is
# assumed that the JupyterHub deployment is called 'jupyterhub' and that
# the user whitelist is maintained under the key 'user_whitelist.txt' in
# the config map with name 'jupyterhub-cfg'.

JUPYTERHUB_DEPLOYMENT=${JUPYTERHUB_DEPLOYMENT:-jupyterhub}
USER_WHITELIST_CONFIG_MAP=${JUPYTERHUB_DEPLOYMENT}-cfg
USER_WHITELIST_CONFIG_MAP_KEY=user_whitelist.txt

# Script must be passed the course name as argument.

if [ "$#" -ne 1 ]; then
    echo "USAGE: `basename $0` course-name" 1>&2
    exit 1
fi

COURSE_NAME=$1

COURSE_NAME=`echo $COURSE_NAME | tr 'A-Z' 'a-z'`

if ! [[ $COURSE_NAME =~ ^[a-z0-9-]*$ ]]; then
    echo "ERROR: Invalid course name $COURSE_NAME." 1>&2
    exit 1
fi

# Assumed that 'oc' is in the current path and that the script is being
# run with appropriate privileges to perform update on project. First
# check that we can find the deployment in the project and then a config
# map.

oc get "dc/$JUPYTERHUB_DEPLOYMENT" -n "$COURSE_NAME" > /dev/null 2>&1

if [ "$?" != "0" ]; then
    echo "ERROR: Cannot find JupyterHub deployment for $COURSE_NAME." 1>&2
    exit 1
fi

oc get "configmap/$USER_WHITELIST_CONFIG_MAP" -n "$COURSE_NAME" > /dev/null 2>&1

if [ "$?" != "0" ]; then
    echo "ERROR: Cannot find config map for $COURSE_NAME." 1>&2
    exit 1
fi

# 

oc get "configmap/$USER_WHITELIST_CONFIG_MAP" -o go-template --template \
    "{{ (index .data \"$USER_WHITELIST_CONFIG_MAP_KEY\") }}" \
    -n "$COURSE_NAME"

if [ "$?" != "0" ]; then
    echo "ERROR: Cannot extract users whitelist from $COURSE_NAME." 1>&2
    exit 1
fi
