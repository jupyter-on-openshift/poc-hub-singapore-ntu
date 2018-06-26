#!/bin/bash

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

if [ "$#" -ge 1 ]; then
    LDAP_USER=$1
    shift
else
    read -p "LDAP Username: " LDAP_USERNAME
fi

if [ x"$LDAP_PASSWORD" = x"" ]; then
    read -s -p "LDAP Password: " LDAP_PASSWORD
fi

echo

DO_RESTART=y

if [ x"$RESTART_PROMPT" != x"N" ]; then
    read -p "New Deployment? [Y/n] " DO_RESTART
fi

DO_UPDATE=y

if [ x"$CONTINUE_PROMPT" != x"N" ]; then
    read -p "Continue? [Y/n] " DO_UPDATE
fi

if ! [[ $DO_UPDATE =~ ^[Yy]$ ]]; then
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

oc get "secret/$LDAP_CREDENTIALS_SECRET" -n "$COURSE_NAME" > /dev/null 2>&1

if [ "$?" != "0" ]; then
    echo "ERROR: Cannot find LDAP credentials secret for $COURSE_NAME."
    exit 1
fi

# We need to replace the existing secret.

oc create secret generic "$LDAP_CREDENTIALS_SECRET" \
    -o json --dry-run \
    --from-literal=user="$LDAP_USERNAME" \
    --from-literal=password="$LDAP_PASSWORD" \
    | oc replace -f -

if [ "$?" != "0" ]; then
    echo "ERROR: Failed to update LDAP credentials secret for $COURSE_NAME."
    exit 1
fi

# Trigger a new deployment if requested.

if [[ $DO_RESTART =~ ^[Yy]$ ]]; then
    oc rollout latest "dc/$JUPYTERHUB_DEPLOYMENT"
fi

if [ "$?" != "0" ]; then
    echo "ERROR: Failed to start new deployment for $COURSE_NAME."
    exit 1
fi
