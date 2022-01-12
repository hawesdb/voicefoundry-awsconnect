#!/bin/bash
RED='\033[1;31m'
NC='\033[0m' # No Color

DEFAULT_STACK_NAME='voicefoundry'
DEFAULT_CONNECT_ARN=''

#####################################################
# PRINT HEADER                                      #
#####################################################
cat << EOF

#####################################################
#                                                   #
# CONFIGURE THE CONFIG                              #
#                                                   #
#####################################################

EOF

#####################################################
# CONFIG                                            #
#####################################################
CONFIG_FILE=.cloudformation-config
if [ -f $CONFIG_FILE ]; then
  source $CONFIG_FILE
  DEFAULT_CONNECT_ARN=$CONNECTARN
  if [ $STACKNAME ]; then
    DEFAULT_STACK_NAME=$STACKNAME
  fi
fi

#####################################################
# USER INPUT                                        #
#####################################################
ATTEMPTS=0
while [ $ATTEMPTS -lt 3 ] && [ -z $connectArn ]; do
  [[ -z $DEFAULT_CONNECT_ARN ]] && printConnectArn="NONE" || printConnectArn=$DEFAULT_CONNECT_ARN
  read -e -p "Connect Instance ARN[$printConnectArn]: " connectArn
  # No input and no default
  if [ -z $connectArn ] && [ -z $DEFAULT_CONNECT_ARN ]; then
    ATTEMPTS=$[$ATTEMPTS+1]
    printf "${RED}ERROR${NC} Please input an instance ARN\n\n"
  # no input but default found
  elif [ -z $connectArn ] && [ -n $DEFAULT_CONNECT_ARN ]; then
    connectArn=$DEFAULT_CONNECT_ARN
  fi
done

# Too many attempts
if [ $ATTEMPTS -eq 3 ]; then
  printf "Too many attempts, quitting..."
  exit
fi

read -e -p "Stack Name[${DEFAULT_STACK_NAME}]: " stackName
if [ -z $stackName ]; then
  stackName=$DEFAULT_STACK_NAME
fi

# Update the config file with the new data
printf "\nUpdating config file...\n"
if [ ! -f $CONFIG_FILE ]; then
  touch $CONFIG_FILE
fi
echo "CONNECTARN=$connectArn" > $CONFIG_FILE
echo "STACKNAME=$stackName" >> $CONFIG_FILE

# aws ecr create-repository --repository-name hello-world --image-scanning-configuration scanOnPush=true --image-tag-mutability MUTABLE