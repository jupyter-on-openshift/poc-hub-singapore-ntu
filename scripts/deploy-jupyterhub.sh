#!/bin/bash

# All inputs need to be provided through prompts.

read -p "Course Name: " COURSE_NAME

read -p "Notebook Repository URL: " NOTEBOOK_REPOSITORY_URL
read -p "Notebook Repository Context Dir: " NOTEBOOK_REPOSITORY_CONTEXT_DIR

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

# Go back to failing only when our checks fail.

set +e

# Deploy JupyterHub in the project.

oc new-app -n "$COURSE_NAME" --template jupyterhub \
    --param COURSE_NAME="$COURSE_NAME" \
    --param NOTEBOOK_REPOSITORY_URL="$NOTEBOOK_REPOSITORY_URL" \
    --param NOTEBOOK_REPOSITORY_CONTEXT_DIR="$NOTEBOOK_REPOSITORY_CONTEXT_DIR" \
    --param LDAP_SEARCH_USER="$LDAP_SEARCH_USER" \
    --param LDAP_SEARCH_PASSWORD="$LDAP_SEARCH_PASSWORD" \
    --param JUPYTERHUB_ADMIN_USERS="$JUPYTERHUB_ADMIN_USERS"

if [ "$?" != "0" ]; then
    echo "ERROR: Cannot deploy JupyterHub for $COURSE_NAME."
    exit 1
fi
