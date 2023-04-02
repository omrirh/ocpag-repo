#!/bin/bash

# Function log
# Arguments:
#   $1 are for the options for echo
#   $2 is for the message
#   \033[0K\r - Trailing escape sequence to leave output on the same line
function log {
	if [ -z "$2" ]; then
		echo -e "\033[0K\r\033[1;36m$1\033[0m"
	else
		echo -e $1 "\033[0K\r\033[1;36m$2\033[0m"
	fi
}

clear
log "=================================================="
log "Welcome to the OpenShift Self-Extracting installer"
log "=================================================="
log ""
log "This will extract the OpenShift Supporting Service Set to a destination"
log "directory provided by the user."
log ""
log "Please make sure that you have enough space so that the"
log "extraction process is successful"
log ""

if [ -f /tmp/.destdir ]; then
  DESTDIR=$(cat /tmp/.destdir)
else
  DESTDIR=""
fi 

while [ ".$DESTDIR" == "." ]
do
   log -n "Please enter destination directory: "
   read ans

   DESTDIR=$ans
   if [ ! -d $DESTDIR ]; then 
     log -n "Creating $DESTDIR ..."
	 mkdir -p $DESTDIR
	 if [ $? == 0 ]; then
       log "Creating $DESTDIR ... done"
	   break
	 else 
       log "Creating $DESTDIR ... failed"
       log "Make sure you can create $DESTDIR destination ... exiting"
	   exit 1
	 fi
   fi
done

if [ ! -f /tmp/.destdir ]; then
  echo $DESTDIR > /tmp/.destdir
fi

log -n "Creating OCP CloudCLI $DESTDIR/cloud-dependencies ... "
mkdir -p $DESTDIR/cloud-dependencies
if [ $? == 0 ]; then
  log "Creating OCP CloudCLI $DESTDIR/cloud-dependencies ... done"
else
  log "Creating OCP CloudCLI $DESTDIR/cloud-dependencies ... failed"
  log "Ensure you have the proper permissions to create $DESTDIR/cloud-dependencies"
  exit 2
fi

log -n "Copying OCP CloudCLI tarball to $DESTDIR"
cp ./ocp-cloudcli-dependencies.tar $DESTDIR
if [ $? == 0 ]; then
  log "Copying OCP CloudCLI tarball to $DESTDIR ... done"
else
  log "Copying OCP CloudCLI tarball to $DESTDIR ... failed"
  log "Ensure you have the proper permissions on $DESTDIR"
  exit 3
fi

filename=ocp-cloudcli-dependencies.tar
tar -xvf ./$filename -C "$DESTDIR/cloud-dependencies"  &&
  echo "OCP CloudCLI [$(basename $filename)] extracted successfully!"
