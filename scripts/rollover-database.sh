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

# Script can optionally be passed the course name and a version number.
# If not supplied the user will be prompted to supply them.

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
    VERSION_NUMBER=$1
    shift
else
    read -p "Version Number: " VERSION_NUMBER
fi

VERSION_NUMBER=$(trim $VERSION_NUMBER)

if [ "$VERSION_NUMBER" == "" ]; then
    echo "ERROR: Version number cannot be empty."
    exit 1
fi

if ! [[ $VERSION_NUMBER =~ ^[0-9]*$ ]]; then
    echo "ERROR: Invalid version number $VERSION_NUMBER."
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

echo "WARNING: Will rollover database for $COURSE_NAME."

read -p "Continue? [y/N] " DO_UPDATE

if ! [[ $DO_UPDATE =~ ^[Yy]$ ]]; then
    exit 1
fi

export DO_UPDATE
export CONTINUE_PROMPT=n
export DO_RESTART=n

# Save a copy of input config maps for admin users and user whitelist.

TIMESTAMP=`date "+%Y-%m-%d-%H-%M-%S"`

echo "INFO: Extracting input config map for admin users."

`dirname $0`/extract-admin-users.sh "$COURSE_NAME" > /tmp/admin_users-$TIMESTAMP.txt

if [ "$?" != "0" ]; then
    echo "ERROR: Cannot extract admin users for $COURSE_NAME."
    exit 1
fi

echo "INFO: Extracting input config map for users whitelist."

`dirname $0`/extract-user-whitelist.sh "$COURSE_NAME" > /tmp/user_whitelist-$TIMESTAMP.txt

if [ "$?" != "0" ]; then
    echo "ERROR: Cannot extract user whitelist for $COURSE_NAME."
    exit 1
fi

# Save a copy of backup config maps for admin users and user whitelist.
# These are the ones created periodically from the JupyterHub database.

echo "INFO: Extracting backup config map for admin users."

`dirname $0`/extract-admin-users-backup.sh "$COURSE_NAME" > /tmp/admin_users-backup-$TIMESTAMP.txt

if [ "$?" != "0" ]; then
    echo "ERROR: Cannot extract admin users backup for $COURSE_NAME."
    exit 1
fi

echo "INFO: Extracting backup config map for users whitelist."

`dirname $0`/extract-user-whitelist-backup.sh "$COURSE_NAME" > /tmp/user_whitelist-backup-$TIMESTAMP.txt

if [ "$?" != "0" ]; then
    echo "ERROR: Cannot extract user whitelist backup for $COURSE_NAME."
    exit 1
fi

# Now ensure that JupyterHub and the database are not running.

echo "INFO: Shutting down JupyterHub."

oc scale --replicas=0 "dc/$JUPYTERHUB_DEPLOYMENT" -n "$COURSE_NAME"

oc rollout status "dc/$JUPYTERHUB_DEPLOYMENT" -n "$COURSE_NAME"

echo "INFO: Shutting down PostgreSQL."

oc scale --replicas=0 "dc/$JUPYTERHUB_DEPLOYMENT-database" -n "$COURSE_NAME"

oc rollout status "dc/$JUPYTERHUB_DEPLOYMENT-database" -n "$COURSE_NAME"

# Stop any Jupyter notebook instances.

echo "INFO: Shutting down any Jupyter notebook instances."

oc delete pods \
    --selector "app=$JUPYTERHUB_DEPLOYMENT,component=singleuser-server" \
    -n "$COURSE_NAME"

# Create a new database volume for the database with version number.

echo "INFO: Create new database directory."

`dirname $0`/create-database-directory.sh "$COURSE_NAME" "$VERSION_NUMBER"

if [ "$?" != "0" ]; then
    echo "ERROR: Cannot create database directory."
    exit 1
fi

echo "INFO: Create new persistent volume."

`dirname $0`/create-database-volume.sh "$COURSE_NAME" "$VERSION_NUMBER"

if [ "$?" != "0" ]; then
    echo "ERROR: Cannot create persistent volume."
    exit 1
fi

# Unmount the existing database persistent volume from PostgreSQL.

echo "INFO: Unmounting existing database persistent volume."

oc set volume "dc/$JUPYTERHUB_DEPLOYMENT-database" --remove \
    --name data -n "$COURSE_NAME"

if [ "$?" != "0" ]; then
    echo "ERROR: Cannot unmount database persistent volume."
    exit 1
fi

# Now create a new persistent volume claim.

echo "INFO: Create new persistent volume claim."

oc process -f `dirname $0`/../templates/database-claim.json \
    --param COURSE_NAME="$COURSE_NAME" \
    --param VERSION_NUMBER="$VERSION_NUMBER" | \
    oc create -f - -n "$COURSE_NAME"

if [ "$?" != "0" ]; then
    echo "ERROR: Cannot create persistent volume claim."
    exit 1
fi

# Mount new persistent volume claim.

echo "INFO: Mount new persistent volume claim."

oc set volume "dc/$JUPYTERHUB_DEPLOYMENT-database" --add \
    --claim-name "$JUPYTERHUB_DEPLOYMENT-database-pvc$VERSION_NUMBER" \
    --name data --mount-path /var/lib/pgsql/data -n "$COURSE_NAME"

if [ "$?" != "0" ]; then
    echo "ERROR: Cannot mount new persistent volume claim."
    exit 1
fi

# Start up PostgreSQL.

echo "INFO: Start up PostgreSQL."

oc scale --replicas=1 "dc/$JUPYTERHUB_DEPLOYMENT-database" -n "$COURSE_NAME"

oc rollout status "dc/$JUPYTERHUB_DEPLOYMENT-database" -n "$COURSE_NAME"

# Update input config maps from backups.

echo "INFO: Update input config map for admin users with backup."

`dirname $0`/update-admin-users.sh "$COURSE_NAME" \
    /tmp/admin_users-backup-$TIMESTAMP.txt

echo "INFO: Update input config map for users whitelist with backup."

`dirname $0`/update-user-whitelist.sh "$COURSE_NAME" \
    /tmp/user_whitelist-backup-$TIMESTAMP.txt

# Start up JupyterHub.

echo "INFO: Start up JupyterHub."

oc scale --replicas=1 "dc/$JUPYTERHUB_DEPLOYMENT" -n "$COURSE_NAME"

oc rollout status "dc/$JUPYTERHUB_DEPLOYMENT" -n "$COURSE_NAME"

# Revert input config maps to originals.

echo "INFO: Revert input config map for admin users."

`dirname $0`/update-admin-users.sh "$COURSE_NAME" \
    /tmp/admin_users-$TIMESTAMP.txt

echo "INFO: Revert input config map for users whitelist."

`dirname $0`/update-user-whitelist.sh "$COURSE_NAME" \
    /tmp/user_whitelist-$TIMESTAMP.txt
