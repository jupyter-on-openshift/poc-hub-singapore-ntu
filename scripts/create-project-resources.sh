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

if [ "$#" -ge 1 ]; then
    PROJECT_RESOURCES=$1
    shift
else
    read -p "Project Resources: " PROJECT_RESOURCES
fi

if [ x"$CONTINUE_PROMPT" != x"n" ]; then
    read -p "Continue? [Y/n] " DO_UPDATE
fi

if ! [[ $DO_UPDATE =~ ^[Yy]?$ ]]; then
    exit 1
fi

# Assumed that 'oc' is in the current path and that the script is being
# run with appropriate privileges to perform update on project. First
# check that there is a project already with required name.

oc get "project/$COURSE_NAME" > /dev/null 2>&1

if [ "$?" != "0" ]; then
    echo "ERROR: Project for $COURSE_NAME doesn't exist."
    exit 1
fi

# Load the project resources.

oc create -f "$PROJECT_RESOURCES" -n "$COURSE_NAME"

if [ "$?" != "0" ]; then
    echo "ERROR: Cannot load project resources for $COURSE_NAME."
    exit 1
fi

# Link secrets to builder service account if flagged. Must have labels
# of app=jupyterhub and link=builder.

for name in `oc get secrets --selector \
  app=${JUPYTERHUB_DEPLOYMENT},link=builder \
  --template='{{range .items}}{{.metadata.name}}{{" "}}{{end}}' \
  -n "$COURSE_NAME"`; do
    oc secrets link builder $name -n "$COURSE_NAME"
done
