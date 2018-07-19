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

# Script can optionally be passed the course name. If not supplied the
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

# Assumed that 'oc' is in the current path and that the script is being
# run with appropriate privileges to perform update on project. First
# check that a project for the course exists.

oc get "project/$COURSE_NAME" > /dev/null 2>&1

if [ "$?" != "0" ]; then
    echo "INFO: Project for $COURSE_NAME doesn't exist."
    exit 0
fi

# Now make sure the project looks like it contains JupyterHub.

oc get "dc/$JUPYTERHUB_DEPLOYMENT" -n "$COURSE_NAME" > /dev/null 2>&1

if [ "$?" != "0" ]; then
    echo "ERROR: Cannot find JupyterHub deployment for $COURSE_NAME."
    exit 1
fi

# Confirm we are still good to go.

echo "WARNING: Will delete project $COURSE_NAME."

read -p "Continue? [Y/n] " DO_UPDATE

if ! [[ $DO_UPDATE =~ ^[Yy]?$ ]]; then
    exit 1
fi

# Delete the project.

oc delete project "$COURSE_NAME"

if [ "$?" != "0" ]; then
    echo "ERROR: Cannot delete the project for $COURSE_NAME."
    exit 1
fi
