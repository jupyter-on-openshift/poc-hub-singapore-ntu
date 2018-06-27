#!/bin/bash
if [ "$#" -ge 1 ]; then
     COURSE_NAME = $1;
     shift
else
     read -p "COURSE NAME:" COURSE_NAME
fi

if [ "$#" -ge 1 ]; then
     NFS_NOTEBOOKS_PATH=$1
     shift
else
     read -p "NFS PATH FOR NOTEBOOKS: " NFS_NOTEBOOKS_PATH
fi

export COURSE_NAME

export NFS_NOTEBOOKS_PATH

# Mount NFS mount point of jupyterhub

mount_a_path(){
     echo "trying to mount $1"
     # Check whether the desired directory already exists
     mount | grep "$1 on /mnt" > /dev/null 2>&1
     #If the desired directory does't exists, try mounting
     if [ "$?" = 1 ]
     then
          try-mount $1        
     #If the desired directory alreday mounted, try unmounting
     elif [ "$?" = 0 ]
     then
          echo "directory $1 already mounted..so first unmounting"
          unmount_a_path $1
          echo "trying again to mount $1.."
          try-mount $1 
     fi
}

try-mount(){
     for i in {1..5}
     do
          echo "try $i"
          mount $1 /mnt
          sleep 5
          if [ "$?" = 0 ]
          then
               exit 0
          else
               echo "mount failed after try $i"
          fi
     done
}

# Unmount NFS mount point of JupyterHub

unmount_a_path(){
     echo "unmounting $1"
     mount | grep "$1 on /mnt" > /dev/null 2>&1
     if [ $? = 0 ]
     then
          try-unmount $1
     else
          echo "$1 is not mounted at all"
     fi
}

try-unmount(){
     for i in {1..5}
     do
          echo "try $i"
          unmount /mnt
          sleep 5
          if [ "$?" = 0 ]
          then
               exit 0
          else
               echo "unmount failed after try $i"
          fi
     done
}

# Creating shared path for JupyterHub Notebooks. Changing ownership and permission

create_share_path_change_ownership_and_permission(){
     echo "creating shared path for JupyterHub $1. Changing ownership and permission..."
     #Check if the directory already exists
     DIRECTORY=$1-$2
     if [ -d "$DIRECTORY" ]; then
          echo "This directory already exists ! exiting..."
          exit 0
     fi
     mkdir /mnt/$1-${2}
     chown nfsnobody:root /mnt/$1-${2}
     chmod 0770 /mnt/$1-${2}
}

mount_a_path $NFS_DB_PATH

create_share_path_change_ownership_and_permission notebooks $COURSE_NAME

unmount_a_path $NFS_DB_PATH



