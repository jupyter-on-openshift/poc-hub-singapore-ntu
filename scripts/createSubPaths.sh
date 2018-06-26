#!/bin/bash
if [ "$#" -ge 1 ]; then
    COURSE_NAME = $1;
    shift
else
   read -p "COURSE NAME:" COURSE_NAME
fi

if [ "$#" -ge 1 ]; then
   NFS_DB_PATH=$1
   shift
else
   read -p "NFS PATH FOR DB: " NFS_DB_PATH
fi

if [ "$#" -ge 1 ]; then
   NFS_NOTEBOOK_PATH=$1
   shift
else
   read -p "NFS PATH FOR NOTEBOOKS: " NFS_NOTEBOOK_PATH
fi

if [ "$#" -ge 1 ]; then
   PV_RESOURCE_DEF_PATH_DB=$1
   shift
else
   read -p "PV RESOURCE DEFINITION PATH: " PV_RESOURCE_DEF_PATH_DB
fi

if [ "$#" -ge 1 ]; then
   PV_RESOURCE_DEF_PATH_NOTEBOOKS=$1
   shift
else
   read -p "PV RESOURCE DEFINITION PATH: " PV_RESOURCE_DEF_PATH_NOTEBOOKS
fi 

mount_a_path(){
# Mount NFS mount point of jupyterhub DB
echo "Mounting $1"
isMounted=`mount | grep "$1"`
if [ "$isMounted" = "" ];then
     mount $1 /mnt
     sleep 5
     isMounted=`mount | grep "$1"`
     if [ "$isMounted" = "" ];then
     echo "issue with mount point -> $1 is NOT mounted"
     else
     echo "$1 is MOUNTED"
     fi
fi
}

unmount_a_path(){
#Unmount NFS mount point of Jupyter DB
echo "Unmounting $1"
mount | grep $1 > /dev/null 2>&1
if [ $? = 1 ];then
  echo "Not mounted at all!"
  exit
 else
   umount /mnt
   sleep 10
   mount | grep $1" > /dev/null 2>&1
   if [ $? = 1 ];then
   echo "Ok...unmounted"
   else
   fi
fi
}

create_share_path_change_ownership_and_permission(){

#Create shared path for JupyterHub DB. Change ownership and permission

 echo "Creating shared path for JupyterHub DB. Changing ownership and permission..."
 mkdir /mnt/$1-${2}
 chown nfsnobody:root /mnt/$1-${2}
 chmod 0770 /mnt/$1-${2}
}

mount_a_path $NFS_DB_PATH
create_share_path_change_ownership_and_permission database $COURSE_NAME
unmount_a_path $NFS_DB_PATH

mount_a_path $NFS_NOTEBOOK_PATH
create_share_path_change_ownership_and_permission notebooks $COURSE_NAME
unmount_a_path $NFS_NOTEBOOK_PATH




   

