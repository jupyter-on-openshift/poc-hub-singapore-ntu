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

NFS_SERVER_NAME=${NFS_SERVER_NAME:-sds.ntu.edu.sg}
NFS_SERVER_SHARE=${NFS_SERVER_SHARE:-/NTU/SPMS/openshift/jupyter}

# Script can optionally be passed the course name and a version number.
# If not supplied the user will be prompted to supply them. There is no
# strict need for the version number, which is more relevant to the
# database volume, but support it just in case there is a reason to
# start over with storage for notebooks.

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

if [ x"$CONTINUE_PROMPT" != x"n" ]; then
    read -p "Continue? [Y/n] " DO_UPDATE
fi

if ! [[ $DO_UPDATE =~ ^[Yy]?$ ]]; then
    exit 1
fi

# Check whether there is any directory already mounted on /mnt, where we
# want to temporarily mount the NFS share in which notebooks will be
# stored. If there is, we stop immediately and expect the user to work
# out why there is a directory mounted and unmount it so we can continue.

if mount | grep " on /mnt " > /dev/null 2>&1; then
    echo "ERROR: The temporary mount directory /mnt is already in use."
    exit 1
fi

# Now mount the NFS server share where notebooks will be stored on /mnt.
# Check whether mounted in a loop in case doesn't show as mounted
# immediately.

mount "$NFS_SERVER_NAME:$NFS_SERVER_SHARE" /mnt

if [ "$?" != "0" ]; then
    echo "ERROR: $NFS_SERVER_NAME:$NFS_SERVER_SHARE could not be mounted."
    exit 1
fi

MOUNTED=0

for _ in {1..5}; do
    if mount | grep "$NFS_SERVER_SHARE on /mnt " > /dev/null 2>&1; then
        MOUNTED=1
        break
    fi
    sleep 3
done

if [ "$MOUNTED" != "1" ]; then
    echo "ERROR: NFS share $NFS_SERVER_SHARE not showing as mounted on /mnt."
    exit 1
fi

# Now check to see whether the notebooks directory we want to create
# already exists and fail if it does.

NFS_NOTEBOOKS_DIRECTORY=/mnt/notebooks-$COURSE_NAME-pv$VERSION_NUMBER

if [ -d $NFS_NOTEBOOKS_DIRECTORY ]; then
    echo "ERROR: Directory $NFS_NOTEBOOKS_DIRECTORY already exists."
    exit 1
fi

# The target directory doesn't exist so create it and set ownership and
# permissions. We expect the parent directory to already exist.

echo "INFO: Will create directory $NFS_NOTEBOOKS_DIRECTORY."

mkdir $NFS_NOTEBOOKS_DIRECTORY

if [ "$?" != "0" ]; then
    echo "ERROR: Could not create directory $NFS_NOTEBOOKS_DIRECTORY."
    exit 1
fi

chown nfsnobody:root $NFS_NOTEBOOKS_DIRECTORY

if [ "$?" != "0" ]; then
    echo "ERROR: Could not set ownership on directory $NFS_NOTEBOOKS_DIRECTORY."
    exit 1
fi

chmod u+rwx,g+rws $NFS_NOTEBOOKS_DIRECTORY

if [ "$?" != "0" ]; then
    echo "ERROR: Could not set permissions on directory $NFS_NOTEBOOKS_DIRECTORY."
    exit 1
fi

# All done, unmount the NFS share. Assume the unmount will be done.

umount /mnt

if [ "$?" != "0" ]; then
    echo "ERROR: Could not unmount the directory /mnt."
    exit 1
fi
