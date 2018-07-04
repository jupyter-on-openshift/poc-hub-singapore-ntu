#!/bin/bash

SERVER=$1
SESSIONS=$2
DELAY=$3

for (( i=0; i<=$SESSIONS; i++ )); do
    echo "Spawning user #$i."
    rm -f /tmp/jupyterhub-cookies.txt
    curl -sL -c /tmp/jupyterhub-cookies.txt -o /dev/null $SERVER/hub/spawn
    sleep $DELAY
done
