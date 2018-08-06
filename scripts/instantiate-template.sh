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
    NOTEBOOK_REPOSITORY_URL=$1
    shift
else
    read -p "Notebook Repository URL: " NOTEBOOK_REPOSITORY_URL
fi

NOTEBOOK_REPOSITORY_URL=$(trim $NOTEBOOK_REPOSITORY_URL)

if [ "$NOTEBOOK_REPOSITORY_URL" == "" ]; then
    echo "ERROR: Repository URL cannot be empty."
    exit 1
fi

if [ "$#" -ge 1 ]; then
    NOTEBOOK_REPOSITORY_CONTEXT_DIR=$1
    shift
else
    read -p "Notebook Repository Context Dir: " NOTEBOOK_REPOSITORY_CONTEXT_DIR
fi

if [ "$#" -ge 1 ]; then
    NOTEBOOK_REPOSITORY_REFERENCE=$1
    shift
else
    read -p "Notebook Repository Reference [master]: " NOTEBOOK_REPOSITORY_REFERENCE
fi

if [ "$#" -ge 1 ]; then
    LDAP_SEARCH_USER=$1
    shift
else
    read -p "LDAP Search User: " LDAP_SEARCH_USER
fi

LDAP_SEARCH_USER=$(trim $LDAP_SEARCH_USER)

if [ "$LDAP_SEARCH_USER" == "" ]; then
    echo "ERROR: LDAP search user cannot be empty."
    exit 1
fi

if [ "$#" -ge 1 ]; then
    LDAP_SEARCH_PASSWORD=$1
    shift
else
    read -s -p "LDAP Search Password: " LDAP_SEARCH_PASSWORD
    echo
fi

LDAP_SEARCH_PASSWORD=$(trim $LDAP_SEARCH_PASSWORD)

if [ "$LDAP_SEARCH_PASSWORD" == "" ]; then
    echo "ERROR: LDAP search user password cannot be empty."
    exit 1
fi

if [ "$#" -ge 1 ]; then
    JUPYTERHUB_ADMIN_USERS=$1
    shift

    OPTIONAL_ARGS=y
else
    read -p "JupyterHub Admin Users: " JUPYTERHUB_ADMIN_USERS
fi

if [ "$#" -ge 1 ]; then
    VERSION_NUMBER=$1
    shift
else
    if [ x"$OPTIONAL_ARGS" != x"y" ]; then
        read -p "Version Number: " VERSION_NUMBER
    fi
fi

if [ x"$CONTINUE_PROMPT" != x"n" ]; then
    read -p "Continue? [Y/n] " DO_UPDATE
fi

if ! [[ $DO_UPDATE =~ ^[Yy]?$ ]]; then
    exit 1
fi

# Deploy JupyterHub in the project.

oc new-app -n "$COURSE_NAME" --template jupyterhub \
    --param APPLICATION_NAME="$JUPYTERHUB_DEPLOYMENT" \
    --param COURSE_NAME="$COURSE_NAME" \
    --param NOTEBOOK_REPOSITORY_URL="$NOTEBOOK_REPOSITORY_URL" \
    --param NOTEBOOK_REPOSITORY_CONTEXT_DIR="$NOTEBOOK_REPOSITORY_CONTEXT_DIR" \
    --param NOTEBOOK_REPOSITORY_REFERENCE="$NOTEBOOK_REPOSITORY_REFERENCE" \
    --param LDAP_SEARCH_USER="$LDAP_SEARCH_USER" \
    --param LDAP_SEARCH_PASSWORD="$LDAP_SEARCH_PASSWORD" \
    --param JUPYTERHUB_ADMIN_USERS="$JUPYTERHUB_ADMIN_USERS" \
    --param VERSION_NUMBER="$VERSION_NUMBER"

if [ "$?" != "0" ]; then
    echo "ERROR: Cannot deploy JupyterHub for $COURSE_NAME."
    exit 1
fi
