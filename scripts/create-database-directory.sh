#!/bin/bash

NFS_SERVER_SHARE=${NFS_SERVER_SHARE:-/NTU/SPMS/openshift/jupyterhubdb}

# Script can optionally be passed the course name and a version number.
# If not supplied the user will be prompted to supply them. The reason
# for the version number is that if the database gets corrupted, we need
# to create a new volume for it, rather than try and clear out the old
# one and reuse it. The PostgreSQL instance will be switched to the new
# volume rather than trying to fix the database in the old. The old will
# be left in place to allow forensics to be done if necessary, and to
# avoid potential issues with trying to clear database volume while a
# PostgreSQL instance is still trying to use it.

if [ "$#" -ge 1 ]; then
    COURSE_NAME=$1
    shift
else
    read -p "Course Name: " COURSE_NAME
fi

if [ "$#" -ge 1 ]; then
    VERSION_NUMBER=$1
    shift
else
    read -p "Version Number : " VERSION_NUMBER
fi

if [ x"$CONTINUE_PROMPT" != x"n" ]; then
    read -p "Continue? [Y/n] " DO_UPDATE
fi

if ! [[ $DO_UPDATE =~ ^[Yy]?$ ]]; then
    exit 1
fi

# Check whether there is any directory already mounted on /mnt, where we
# want to temporarily mount the NFS share in which database will be
# stored. If there is, we stop immediately and expect the user to work
# out why there is a directory mounted and unmount it so we can continue.

if mount | grep " on /mnt " > /dev/null 2>&1; then
    echo "ERROR: The temporary mount directory /mnt is already in use."
    exit 1
fi

# Now mount the NFS server share where database will be stored on /mnt.
# Check whether mounted in a loop in case doesn't show as mounted
# immediately.
#
# Note that it is assumed that there is an entry for the NFS share in
# the /etc/fstab file, so we don't need to supply the NFS server name
# or file system type.

mount $NFS_SERVER_SHARE /mnt

if [ "$?" != "0" ]; then
    echo "ERROR: NFS share $NFS_SERVER_SHARE could not be mounted on /mnt."
    exit 1
fi

MOUNTED=

for _ in {1..5}; do
    if mount | grep "$NFS_SERVER_SHARE on /mnt " > /dev/null 2>&1; then
        MOUNTED=1
        break
    fi
    sleep 3
done

if [ x"$MOUNTED" != x"1" ]; then
    echo "ERROR: NFS share $NFS_SERVER_SHARE not showing as mounted on /mnt."
    exit 1
fi

# Now check to see whether the database directory we want to create
# already exists and fail if it does.

NFS_DATABASE_DIRECTORY=/mnt/database-$COURSE_NAME-pv$VERSION_NUMBER

if [ -d $NFS_DATABASE_DIRECTORY ]; then
    echo "ERROR: Directory $NFS_DATABASE_DIRECTORY already exists."
    exit 1
fi

# The target directory doesn't exist so create it and set ownership and
# permissions. We expect the parent directory to already exist.

mkdir $NFS_DATABASE_DIRECTORY

if [ "$?" != "0" ]; then
    echo "ERROR: Could not create directory $NFS_DATABASE_DIRECTORY."
    exit 1
fi

chown nfsnobody:root $NFS_DATABASE_DIRECTORY

if [ "$?" != "0" ]; then
    echo "ERROR: Could not set ownership on directory $NFS_DATABASE_DIRECTORY."
    exit 1
fi

chmod 0770 $NFS_DATABASE_DIRECTORY

if [ "$?" != "0" ]; then
    echo "ERROR: Could not set permissions on directory $NFS_DATABASE_DIRECTORY."
    exit 1
fi

# All done, unmount the NFS share. Assume the unmount will be done.

unmount /mnt

if [ "$?" != "0" ]; then
    echo "ERROR: Could not unmount the directory /mnt."
    exit 1
fi
