#!/bin/bash

# Script can optionally be passed the course name and a version number.
# If not supplied the user will be prompted to supply them.

if [ "$#" -ge 1 ]; then
    COURSE_NAME=$1
    shift
else
    read -p "Course Name: " COURSE_NAME
fi

COURSE_NAME=`echo $COURSE_NAME | tr 'A-Z' 'a-z'`

if ! [[ $COURSE_NAME =~ ^[a-z-]*$ ]]; then
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

# Assumed that 'oc' is in the current path and that the script is being
# run with appropriate privileges to perform update on cluster wide
# resources. Attempt to delete both volumes, even if can't delete the
# first.

STATUS=0

PERSISTENT_VOLUME_NAME=$COURSE_NAME-database-pv$VERSION_NUMBER

oc get "pv/$PERSISTENT_VOLUME_NAME" > /dev/null 2>&1

if [ "$?" != "0" ]; then
    echo "INFO: Persistent volume for $COURSE_NAME database does not exist."
else
    oc delete "pv/$PERSISTENT_VOLUME_NAME"

    if [ "$?" != "0" ]; then
        echo "ERROR: Cannot delete database volume for $COURSE_NAME."
        STATUS=1
    fi
fi

PERSISTENT_VOLUME_NAME=$COURSE_NAME-notebooks-pv$VERSION_NUMBER

oc get "pv/$PERSISTENT_VOLUME_NAME" > /dev/null 2>&1

if [ "$?" != "0" ]; then
    echo "INFO: Persistent volume for $COURSE_NAME notebooks does not exist."
else
    oc delete "pv/$PERSISTENT_VOLUME_NAME"

    if [ "$?" != "0" ]; then
        echo "ERROR: Cannot delete notebooks volume for $COURSE_NAME."
        STATUS=1
    fi
fi

exit $STATUS
