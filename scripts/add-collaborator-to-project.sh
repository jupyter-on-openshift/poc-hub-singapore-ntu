#!/bin/bash

# Script must be passed the course name as argument.

if [ "$#" -ne 2 ]; then
    echo "USAGE: `basename $0` course-name username" 1>&2
    exit 1
fi

PROJECT=$1
USERNAME=$2

# Assumed that 'oc' is in the current path and that the script is being
# run with appropriate privileges to perform update on project. Add user
# with edit role. They will be able to makes changes, including deleting
# the application, but not delete project.

oc adm policy add-role-to-user edit "$USERNAME" -n "$PROJECT"
