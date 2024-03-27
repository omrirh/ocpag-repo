#!/bin/sh

#
# copy ocp images to a registry
#
REGISTRY=`hostname -f`
REDHATOPERATORS=0
COMMUNITYOPERATORS=0
MARKETPLACEOPERATORS=0
RHCERTOPERATORS=0


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

function usage () {
  printf "$0 -r <REGISTRY FQDN> -p <PORT> -d <BUNDLE DIR>\n"
  printf "\n"
  printf "$0 -r fedora.redhat.local -p 5000 -d /home/user/work/bundle\n"
  printf "\n"
  printf "The above command will use fedora.redhat.local:500 as the registry endpoint\n"
  exit 1
}

function checkRegistryAuth()
{
  HOST=$1
  CONFIGCHK=0
  DOCKERCHK=0

  log -n "Checking for $HOST in auth files ...  "
#  if [ -d ~/.config ] && [ -f ~/.config/auth.json ]; then
#    RC=$(grep $HOST ~/.config/auth.json)
#	if [ $? == 0 ]; then
#      log "Checking for $HOST in auth files ... ok"
#	  CONFIGCHK=1
#	fi
#  fi
  if [ -d ~/.docker ] && [ -f ~/.docker/config.json ]; then
    RC=$(grep $HOST ~/.docker/config.json)
	if [ $? == 0 ]; then
      log "Checking for $HOST in auth files ... ok"
	  DOCKERCHK=1
	fi
  fi

  if [ $DOCKERCHK -eq 0 ]; then ## || [ $CONFIGCHK -eq 0 ]; then
	if [ $DOCKERCHK -eq 0 ]; then
      log "Please check your authentication files in ~/.docker/config.json"
	fi
	exit
  fi
}

while getopts "r:p:d:ocvm" opt
do
    case $opt in
    (c) COMMUNITYOPERATORS=1
        ;;
    (o) REDHATOPERATORS=1
        ;;
    (m) MARKETPLACEOPERATORS=1
        ;;
    (v) RHCERTOPERATORS=1
        ;;
    (p) PORT=$OPTARG
        ;;
    (r) FQDN=$OPTARG
        ;;
    (d) BUNDLEDIR=$OPTARG
        ;;
    (*) printf "Illegal option '-%s'\n" "$opt" && exit 1
        ;;
    esac
done


# Checking the arguments
if [ ! -d $BUNDLEDIR ]; then
  log "Directory [ $BUNDLEDIR ] does not exist"
  usage
fi

if [ "$FQDN" != "${FQDN/.}" ]; then
  echo "$FQDN is acceptable" >&2
else
  echo "$FQDN is not acceptable" >&2
  usage
fi

re='^[0-9]+$'
if ! [[ $PORT =~ $re ]] ; then
   echo "error: Not a number" >&2; exit 1
   usage
fi

# Check for oc-mirror
if [ ! -f $BUNDLEDIR/bin/oc-mirror ]; then
  log "Is bundle directory complete?"
  tree $BUNDLEDIR
  usage
fi

checkRegistryAuth $FQDN
if [ $REDHATOPERATORS -eq 1 ]; then
  INDEX=$(grep catalog $BUNDLEDIR/operators/redhat/rh-operator-catalog-operators.yml | grep -v '#' | cut -d '/' -f 3)
  log "Mirroring $INDEX to $FQDN:$PORT"
  oc-mirror --from=$BUNDLEDIR/operators/redhat docker://$FQDN:$PORT/olm/redhat --dest-skip-tls
elif [ $COMMUNITYOPERATORS -eq 1 ]; then
  INDEX=$(grep catalog $BUNDLEDIR/operators/community/rh-community-operators.yml | grep -v '#' | cut -d '/' -f 3)
  log "Mirroring $INDEX to $FQDN:$PORT"
  oc-mirror --from=$BUNDLEDIR/operators/community docker://$FQDN:$PORT/olm/redhat --dest-skip-tls
elif [ $MARKETPLACEOPERATORS -eq 1 ]; then
  cd $BUNDLEDIR/operators/marketplace
  INDEX=$(grep catalog $BUNDLEDIR/operators/marketplace/rh-marketplace-operators.yml | grep -v '#' | cut -d '/' -f 3)
  log "Mirroring $INDEX to $FQDN:$PORT"
  oc-mirror --from=$BUNDLEDIR/operators/marketplace docker://$FQDN:$PORT/olm/redhat --dest-skip-tls
  cd -
elif [ $RHCERTOPERATORS -eq 1 ]; then
  cd $BUNDLEDIR/operators/certified
  INDEX=$(grep catalog $BUNDLEDIR/operators/certified/rh-certified-operators.yml | grep -v '#' | cut -d '/' -f 3)
  log "Mirroring $INDEX to $FQDN:$PORT"
  oc-mirror --from=$BUNDLEDIR/operators/certified docker://$FQDN:$PORT/olm/redhat --dest-skip-tls
  cd -
else
  oc-mirror --from=$BUNDLEDIR/openshift-release-dev docker://$FQDN:$PORT/openshift-release-dev --dest-skip-tls
fi