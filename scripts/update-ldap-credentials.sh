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
# the secret containing the LDAP user credentials is 'jupyterhub-ldap'.

JUPYTERHUB_DEPLOYMENT=${JUPYTERHUB_DEPLOYMENT:-jupyterhub}
LDAP_CREDENTIALS_SECRET=${JUPYTERHUB_DEPLOYMENT}-ldap

# Script can optionally be passed the course name and name of LDAP user.
# If not supplied the user will be prompted to supply them. The password
# cannot be supplied on the command line as an argument and the user
# will always be prompted for it. Alternatively the password can be
# supplied via an environment variable. This would only be used when
# executing this script from a wrapper which is updating the LDAP user
# credentials for more than one course at a time.

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
    LDAP_SEARCH_USER=$1
    shift
else
    read -p "LDAP Search User: " LDAP_SEARCH_USER
fi

if [ x"$LDAP_SEARCH_PASSWORD" = x"" ]; then
    read -s -p "LDAP Search Password: " LDAP_SEARCH_PASSWORD
fi

echo

if [ x"$RESTART_PROMPT" != x"n" ]; then
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
# check that we can find the deployment in the project and then a secret.

oc get "dc/$JUPYTERHUB_DEPLOYMENT" -n "$COURSE_NAME" > /dev/null 2>&1

if [ "$?" != "0" ]; then
    echo "ERROR: Cannot find JupyterHub deployment for $COURSE_NAME."
    exit 1
fi

oc get "secret/$LDAP_CREDENTIALS_SECRET" -n "$COURSE_NAME" > /dev/null 2>&1

if [ "$?" != "0" ]; then
    echo "ERROR: Cannot find LDAP credentials secret for $COURSE_NAME."
    exit 1
fi

# We need to replace the existing secret.

oc create secret generic "$LDAP_CREDENTIALS_SECRET" \
    -o json --dry-run \
    --from-literal=user="$LDAP_SEARCH_USER" \
    --from-literal=password="$LDAP_SEARCH_PASSWORD" \
    | oc replace -f - -n "$COURSE_NAME"

if [ "$?" != "0" ]; then
    echo "ERROR: Failed to update LDAP credentials secret for $COURSE_NAME."
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
