#!/bin/bash

# Script must be passed input file with course descriptions.

if [ "$#" -lt 1 ]; then
    echo "USAGE: `basename $0` courses-file [args]" 1>&2
    exit 1
fi

COURSES_FILE=$1

shift

if [ "$#" -ge 1 ]; then
    LDAP_SEARCH_USER=$1
    shift
else
    read -p "LDAP Search User: " LDAP_SEARCH_USER
fi

if [ "$#" -ge 1 ]; then
    LDAP_SEARCH_PASSWORD=$1
    shift
else
    read -s -p "LDAP Search Password: " LDAP_SEARCH_PASSWORD
    echo
fi

if [ "$#" -ge 1 ]; then
    JUPYTERHUB_ADMIN_USERS=$1
    shift
else
    read -p "JupyterHub Admin Users: " JUPYTERHUB_ADMIN_USERS
fi

if [ x"$CONTINUE_PROMPT" != x"n" ]; then
    read -p "Continue? [Y/n] " DO_UPDATE
fi

if ! [[ $DO_UPDATE =~ ^[Yy]?$ ]]; then
    exit 1
fi

export DO_UPDATE
export CONTINUE_PROMPT=n

# Iterate over course details from input file and create each one.

while IFS=, read -r COURSE_NAME NOTEBOOK_REPOSITORY_URL \
  NOTEBOOK_REPOSITORY_CONTEXT_DIR NOTEBOOK_REPOSITORY_REFERENCE
do
    echo "INFO: Creating course $COURSE_NAME."

    `dirname $0`/deploy-jupyterhub.sh "$COURSE_NAME" \
      "$NOTEBOOK_REPOSITORY_URL" "$NOTEBOOK_REPOSITORY_CONTEXT_DIR" \
      "$NOTEBOOK_REPOSITORY_REFERENCE" "$LDAP_SEARCH_USER" \
      "$LDAP_SEARCH_PASSWORD" "$JUPYTERHUB_ADMIN_USERS"

done < $COURSES_FILE
