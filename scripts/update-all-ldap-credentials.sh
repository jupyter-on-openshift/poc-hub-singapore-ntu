#!/bin/bash

# Assumed that a project is used for each course and the name of the
# course is used for the project name. Inside of the project, it is
# assumed that the JupyterHub deployment is called 'jupyterhub' and that
# the secret containing the LDAP user credentials is 'jupyterhub-ldap'.

JUPYTERHUB_DEPLOYMENT=${JUPYTERHUB_DEPLOYMENT:-jupyterhub}
LDAP_CREDENTIALS_SECRET=${JUPYTERHUB_DEPLOYMENT}-ldap

# Script can optionally be passed the name of LDAP user. If not supplied
# the user will be prompted to supply it. The password cannot be
# supplied on the command line as an argument and the user will always
# be prompted for it.

if [ "$#" -ge 1 ]; then
    LDAP_USER=$1
    shift
else
    read -p "LDAP Search User: " LDAP_SEARCH_USER
fi

if [ x"$LDAP_SEARCH_PASSWORD" = x"" ]; then
    read -s -p "LDAP Search Password: " LDAP_SEARCH_PASSWORD
fi

export LDAP_SEARCH_PASSWORD

echo

export DO_RESTART=y
export RESTART_PROMPT=n

read -p "New Deployment? [Y/n] " DO_RESTART

export DO_UPDATE=y
export CONTINUE_PROMPT=n

read -p "Continue? [Y/n] " DO_UPDATE

if ! [[ $DO_UPDATE =~ ^[Yy]?$ ]]; then
    exit 1
fi

# Assumed that 'oc' is in the current path and that the script is being
# run with appropriate privileges to perform update on projects for the
# courses. First need to work out which of the projects which can be
# accessed have JupyterHub for a course deployed in them.

PROJECTS=`oc get projects -o go-template --template \
    '{{range .items}}{{.metadata.name}} {{end}}'`

if [ "$?" != "0" ]; then
    echo "ERROR: Failed to get list of projects in cluster."
    exit 1
fi

# Now loop over projects and work out which have both a deployment for
# JupyterHub and a corresponding secret for LDAP user credentials. For
# those that do, attempt to update the credentials for it and start a
# new deployment if requested.

for name in $PROJECTS; do
    oc get "dc/$JUPYTERHUB_DEPLOYMENT" -n "$name" > /dev/null 2>&1

    if [ "$?" != "0" ]; then
        continue
    fi

    oc get "secret/$LDAP_CREDENTIALS_SECRET" -n "$name" > /dev/null 2>&1

    if [ "$?" != "0" ]; then
        continue
    fi

    echo "Updating project for $name."

    `dirname $0`/update-ldap-credentials.sh "$name" "$LDAP_SEARCH_USER"
done
