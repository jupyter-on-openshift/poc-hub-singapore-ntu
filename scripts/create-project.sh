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

if [ "$?" == "0" ]; then
    echo "ERROR: Project for $COURSE_NAME already exists."
    exit 1
fi

# Project doesn't exist so create it.

oc new-project "$COURSE_NAME"

if [ "$?" != "0" ]; then
    echo "ERROR: Cannot create project for $COURSE_NAME."
    exit 1
fi

# Load the template into the project. We don't deploy it from this
# script and for now rely on user going to web console for the project,
# selecting it, filling in fields and creating it.

oc create -f `dirname $0`/../templates/jupyterhub.json -n "$COURSE_NAME"

if [ "$?" != "0" ]; then
    echo "ERROR: Cannot load templates into project for $COURSE_NAME."
    exit 1
fi
