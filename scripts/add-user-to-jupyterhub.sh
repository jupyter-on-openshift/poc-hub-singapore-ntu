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
# assumed that the JupyterHub deployment is called 'jupyterhub'.

JUPYTERHUB_DEPLOYMENT=${JUPYTERHUB_DEPLOYMENT:-jupyterhub}

# Script can optionally be passed the arguments. If not supplied the
# user will be prompted to supply them.

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
    USER_NAME=$1
    shift

    DO_UPDATE=y
    CONTINUE_PROMPT=n

    OPTIONAL_ARGS=y
else
    read -p "Username: " USER_NAME
fi

if [ "$#" -ge 1 ]; then
    ROLE=$1
    shift
else
    if [ x"$OPTIONAL_ARGS" != x"y" ]; then
        read -p "Role: [user] " ROLE
    fi
fi

if [ x"$CONTINUE_PROMPT" != x"n" ]; then
    read -p "Continue? [Y/n] " DO_UPDATE
fi

if ! [[ $DO_UPDATE =~ ^[Yy]?$ ]]; then
    exit 1
fi

# Assumed that 'oc' is in the current path and that the script is being
# run with appropriate privileges to perform update on project. First
# check that we can find the deployment in the project.

oc get "dc/$JUPYTERHUB_DEPLOYMENT" -n "$COURSE_NAME" > /dev/null 2>&1

if [ "$?" != "0" ]; then
    echo "ERROR: Cannot find JupyterHub deployment for $COURSE_NAME."
    exit 1
fi

# Lookup up the URL endpoint for the JupyterHub instance.

REST_API_HOST=`oc get "route/$JUPYTERHUB_DEPLOYMENT" -n "$COURSE_NAME" \
    --template='{{.spec.host}}'`

if [ "$?" != "0" ]; then
    echo "ERROR: Cannot retrieve REST API host for $COURSE_NAME."
    exit 1
fi

REST_API_URL="https://$REST_API_HOST/hub/api"

# Extract the REST API password from the environment of the deployment
# config for the container.

REST_API_PASSWORD=`oc set env "dc/$JUPYTERHUB_DEPLOYMENT" -n "$COURSE_NAME" \
    --list | egrep '^REST_API_PASSWORD=' | sed -e 's/^REST_API_PASSWORD=//'` 

if [ "$?" != "0" ]; then
    echo "ERROR: Cannot retrieve REST API password for $COURSE_NAME."
    exit 1
fi

# Add the new user via the REST API.

python -c "import json; \
    print(json.dumps({'usernames':['$USER_NAME'],'admin':'$ROLE'=='admin'}))" > /tmp/users$$.json

curl -k -H "Authorization: token $REST_API_PASSWORD" -X POST \
    -d @/tmp/users$$.json "$REST_API_URL/users"

rm -f /tmp/users$$.json

echo
