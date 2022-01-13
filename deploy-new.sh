#!/bin/bash
RED='\033[1;31m'
NC='\033[0m' # No Color

CONFIG_FILE=.cloudformation-config

#####################################################
# CONFIG CHECK                                      #
#####################################################
if [ -f $CONFIG_FILE ]; then
  source $CONFIG_FILE
  if [ -z $connect_arn ] || [ -z $ecr_arn ] || [ -z $stack_name ]; then
    printf "${RED}ERROR${NC} Run the configure.sh script to setup the project\n"
    exit
  fi
else
  printf "${RED}ERROR${NC} Run the configure.sh script to setup the project\n"
  exit
fi


#####################################################
# PRINT HEADER                                      #
#####################################################
cat << EOF

#---------------------------------------------------#
# DEPLOYMENT                                        #
# --------------------------------------------------#

EOF
printf "Stack:  $stack_name\n"
$stack_status=$(aws cloudformation describe-stacks --stack-name $stack_name)
printf "Status: ${stack_status#*StackStatus\: }"