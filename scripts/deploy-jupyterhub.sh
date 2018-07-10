#!/bin/bash

# All inputs need to be provided through prompts.

read -p "Course Name: " COURSE_NAME

COURSE_NAME=`echo $COURSE_NAME | tr 'A-Z' 'a-z'`

if ! [[ $COURSE_NAME =~ ^[a-z0-9-]*$ ]]; then
    echo "ERROR: Invalid course name $COURSE_NAME."
    exit 1
fi

read -p "Notebook Repository URL: " NOTEBOOK_REPOSITORY_URL
read -p "Notebook Repository Context Dir: " NOTEBOOK_REPOSITORY_CONTEXT_DIR
read -p "Notebook Repository Reference [master]: " NOTEBOOK_REPOSITORY_REFERENCE

if [ "$NOTEBOOK_REPOSITORY_REFERENCE" = "" ]; then
    NOTEBOOK_REPOSITORY_REFERENCE=master
fi

read -p "LDAP Search User: " LDAP_SEARCH_USER
read -s -p "LDAP Search Password: " LDAP_SEARCH_PASSWORD

echo

read -p "JupyterHub Admin Users: " JUPYTERHUB_ADMIN_USERS

read -p "Continue? [Y/n] " DO_UPDATE

if ! [[ $DO_UPDATE =~ ^[Yy]?$ ]]; then
    exit 1
fi

export DO_UPDATE
export CONTINUE_PROMPT=n

# Fail fast if any of these steps fail.

set -e

# Now run all the steps together to create the directories in the NFS
# shares and create the persistent volumes.

`dirname $0`/create-notebooks-directory.sh "$COURSE_NAME" ""
`dirname $0`/create-notebooks-volume.sh "$COURSE_NAME" ""
`dirname $0`/create-database-directory.sh "$COURSE_NAME" ""
`dirname $0`/create-database-volume.sh "$COURSE_NAME" ""

# Create the project and load the template into it.

`dirname $0`/create-project.sh "$COURSE_NAME"

# Deploy instantiate the template to deploy JupyterHub.

`dirname $0`/instantiate-template.sh "$COURSE_NAME" \
    "$NOTEBOOK_REPOSITORY_URL" "$NOTEBOOK_REPOSITORY_CONTEXT_DIR" \
    "$NOTEBOOK_REPOSITORY_REFERENCE" "$LDAP_SEARCH_USER" \
    "$LDAP_SEARCH_PASSWORD" "$JUPYTERHUB_ADMIN_USERS"
