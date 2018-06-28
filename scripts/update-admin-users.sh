#!/bin/bash

# Assumed that a project is used for each course and the name of the
# course is used for the project name. Inside of the project, it is
# assumed that the JupyterHub deployment is called 'jupyterhub' and that
# the admin users is maintained under the key 'admin_user.txt' in
# the config map with name 'jupyterhub-cfg'.

JUPYTERHUB_DEPLOYMENT=${JUPYTERHUB_DEPLOYMENT:-jupyterhub}
ADMIN_USERS_CONFIG_MAP=${JUPYTERHUB_DEPLOYMENT}-cfg
ADMIN_USERS_CONFIG_MAP_KEY=admin_users.txt

# Script can optionally be passed the course name and name of the file
# containing the admin users. If not supplied the user will be prompted
# to supply them.

if [ "$#" -ge 1 ]; then
    COURSE_NAME=$1
    shift
else
    read -p "Course Name: " COURSE_NAME
fi

if [ "$#" -ge 1 ]; then
    ADMIN_USERS_FILE=$1
    shift
else
    read -p "Admin Users File: " ADMIN_USERS_FILE
fi

read -p "New Deployment? [Y/n] " DO_RESTART

read -p "Continue? [Y/n] " DO_UPDATE

if ! [[ $DO_UPDATE =~ ^[Yy]?$ ]]; then
    exit 1
fi

# Assumed that 'oc' is in the current path and that the script is being
# run with appropriate privileges to perform update on project. First
# check that we can find the deployment in the project and then the
# config map.

oc get "dc/$JUPYTERHUB_DEPLOYMENT" -n "$COURSE_NAME" > /dev/null 2>&1

if [ "$?" != "0" ]; then
    echo "ERROR: Cannot find JupyterHub deployment for $COURSE_NAME."
    exit 1
fi

oc get "configmap/$ADMIN_USERS_CONFIG_MAP" -n "$COURSE_NAME" > /dev/null 2>&1

if [ "$?" != "0" ]; then
    echo "ERROR: Cannot find config map for $COURSE_NAME."
    exit 1
fi

# We need to patch the existing config map in place as there are
# multiple keys within the one config map. We need to convert the file
# contents into valid JSON string to ensure accepted in jsonpatch.
# Note that if the contents haven't changed it will exit saying the
# patch has failed, when reality is there was nothing to change.

ADMIN_USERS_DATA=`python -c "import json; \
    print(json.dumps(open('$ADMIN_USERS_FILE').read()))"`

if [ "$?" != "0" ]; then
    echo "ERROR: Cannot read admin users data file."
    exit 1
fi

oc patch "configmap/$ADMIN_USERS_CONFIG_MAP" \
    -p "{\"data\":{\"$ADMIN_USERS_CONFIG_MAP_KEY\":$ADMIN_USERS_DATA}}" \
    -n "$COURSE_NAME"

if [ "$?" != "0" ]; then
    echo "ERROR: Failed to update admin users for $COURSE_NAME."
    exit 1
fi

# Trigger a new deployment if requested.

if [[ $DO_RESTART =~ ^[Yy]?$ ]]; then
    oc rollout latest "dc/$JUPYTERHUB_DEPLOYMENT" -n "$COURSE_NAME"
fi

if [ "$?" != "0" ]; then
    echo "ERROR: Failed to start new deployment for $COURSE_NAME."
    exit 1
fi
