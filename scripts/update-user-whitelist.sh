#!/bin/bash

# Some bash functions for common tasks.

trim()
{
    local trimmed="$1"

    # Strip leading space.
    trimmed="${trimmed## }"
    # Strip trailing space.
    trimmed="${trimmed%% }"

    echo "$trimmed"
}

# Assumed that a project is used for each course and the name of the
# course is used for the project name. Inside of the project, it is
# assumed that the JupyterHub deployment is called 'jupyterhub' and that
# the user whitelist is maintained under the key 'user_whitelist.txt' in
# the config map with name 'jupyterhub-cfg'.

JUPYTERHUB_DEPLOYMENT=${JUPYTERHUB_DEPLOYMENT:-jupyterhub}
USER_WHITELIST_CONFIG_MAP=${JUPYTERHUB_DEPLOYMENT}-cfg
USER_WHITELIST_CONFIG_MAP_KEY=user_whitelist.txt

# Script can optionally be passed the course name and name of the file
# containing the user whitelist. If not supplied the user will be prompted
# to supply them.

if [ "$#" -ge 1 ]; then
    COURSE_NAME=$1
    shift
else
    read -p "Course Name: " COURSE_NAME
fi

COURSE_NAME=$(trim `echo $COURSE_NAME | tr 'A-Z' 'a-z'`)

if [ "$COURSE_NAME" == "" ]; then
    echo "ERROR: Course name cannot be empty."
    exit 1
fi

if ! [[ $COURSE_NAME =~ ^[a-z0-9-]*$ ]]; then
    echo "ERROR: Invalid course name $COURSE_NAME."
    exit 1
fi

if [ "$#" -ge 1 ]; then
    USER_WHITELIST_FILE=$1
    shift

    DO_RESTART=y
    DO_UPDATE=y
    CONTINUE_PROMPT=n
else
    read -p "User Whitelist File: " USER_WHITELIST_FILE
fi

if [ x"$DO_RESTART" == x"" ]; then
    read -p "New Deployment? [Y/n] " DO_RESTART
fi

if [ x"$CONTINUE_PROMPT" != x"n" ]; then
    read -p "Continue? [Y/n] " DO_UPDATE
fi

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

oc get "configmap/$USER_WHITELIST_CONFIG_MAP" -n "$COURSE_NAME" > /dev/null 2>&1

if [ "$?" != "0" ]; then
    echo "ERROR: Cannot find config map for $COURSE_NAME."
    exit 1
fi

# We need to patch the existing config map in place as there are
# multiple keys within the one config map. We need to convert the file
# contents into valid JSON string to ensure accepted in jsonpatch.
# Note that if the contents haven't changed it will exit saying the
# patch has failed, when reality is there was nothing to change.

USER_WHITELIST_DATA=`python -c "import json; \
    print(json.dumps(open('$USER_WHITELIST_FILE').read()))"`

if [ "$?" != "0" ]; then
    echo "ERROR: Cannot read user whitelist data file."
    exit 1
fi

oc patch "configmap/$USER_WHITELIST_CONFIG_MAP" \
    -p "{\"data\":{\"$USER_WHITELIST_CONFIG_MAP_KEY\":$USER_WHITELIST_DATA}}" \
    -n "$COURSE_NAME"

if [ "$?" != "0" ]; then
    echo "WARNING: Failed to update user whitelist for $COURSE_NAME."
    exit 1
fi

# Trigger a new deployment if requested.

if [[ $DO_RESTART =~ ^[Yy]?$ ]]; then
    oc rollout latest "dc/$JUPYTERHUB_DEPLOYMENT" -n "$COURSE_NAME" && \
      oc rollout status "dc/$JUPYTERHUB_DEPLOYMENT" -n "$COURSE_NAME"

    if [ "$?" != "0" ]; then
        echo "ERROR: Failed to start new deployment for $COURSE_NAME."
        exit 1
    fi
fi
