#!/bin/bash

NFS_SERVER_NAME=${NFS_SERVER_NAME:-sds.ntu.edu.sg}
NFS_SERVER_SHARE=${NFS_SERVER_SHARE:-/NTU/SPMS/openshift/jupyterhubdb}

# Script can optionally be passed the course name and a version number.
# If not supplied the user will be prompted to supply them.

if [ "$#" -ge 1 ]; then
    COURSE_NAME=$1
    shift
else
    read -p "Course Name: " COURSE_NAME
fi

COURSE_NAME=`echo $COURSE_NAME | tr 'A-Z' 'a-z'`

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

# Now check to see whether the database directory we want to delete exists.

NFS_DATABASE_DIRECTORY=/mnt/database-$COURSE_NAME-pv$VERSION_NUMBER

if [ ! -d $NFS_DATABASE_DIRECTORY ]; then
    echo "INFO: Directory $NFS_DATABASE_DIRECTORY does not exist."
    umount /mnt
    exit 0
fi

# Check that we want to keep going.

echo "WARNING: Will delete directory $NFS_DATABASE_DIRECTORY."

read -p "Continue? [Y/n] " DO_UPDATE

if ! [[ $DO_UPDATE =~ ^[Yy]?$ ]]; then
    umount /mnt
    exit 1
fi

# Delete the directory and all its contents.

STATUS=0

rm -rf $NFS_DATABASE_DIRECTORY

if [ "$?" != "0" ]; then
    echo "ERROR: Could not delete directory $NFS_DATABASE_DIRECTORY."
    STATUS=1
fi

# All done, unmount the NFS share. Assume the unmount will be done.

umount /mnt

if [ "$?" != "0" ]; then
    echo "ERROR: Could not unmount the directory /mnt."
    STATUS=1
fi

exit $STATUS
