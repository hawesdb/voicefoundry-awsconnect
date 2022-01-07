#!/bin/bash
RED='\033[1;31m'
NC='\033[0m' # No Color

#####################################################
# PRINT HEADER                                      #
#####################################################
cat << EOF

#####################################################
#                                                   #
# DEPLOYMENT                                        #
#                                                   #
#####################################################

EOF

#####################################################
# CONFIG CHECK                                      #
#####################################################
CONFIG_FILE=.cloudformation-config
if [ -f $CONFIG_FILE ]; then
  source $CONFIG_FILE
  if [ -z $CONNECTARN ] || [ -z $STACKNAME ]; then
    printf "${RED}ERROR::${NC} Run the configure.sh script to setup the project\n"
    exit
  fi
else
  printf "${RED}ERROR::${NC} Run the configure.sh script to setup the project\n"
  exit
fi

#####################################################
# CREATE STACK FUNCTION                             #
#####################################################
create_stack () {
  printf "\nChecking if stack already exists..\n\n"
  aws cloudformation get-stack-policy --stack-name $STACKNAME > /dev/null 2>&1

  if [ $? -eq 0 ]; then
    printf "Stack already exists ... taking you back to the options\n\n"
    display_options
  else
    aws cloudformation create-stack \
    --stack-name $STACKNAME \
    --parameters \
      ParameterKey=ConnectArn,ParameterValue=$CONNECTARN \
    --template-body file://cloudformation.yaml
  fi
}

#####################################################
# PRINT OPTIONS                                     #
#####################################################
display_options () {
  cat << EOF
Please select an option to continue:
  1. Create Cloudformation stack
  2. Update Cloudformation stack
  3. Exit
EOF

  ATTEMPTS=0
  while [ -z $option ] && [ $ATTEMPTS -lt 3 ]; do
    read -n1 -e -p "Option: " chosenOption
    if ((chosenOption >= 1 && chosenOption <= 3)); then
      option=$chosenOption
      break
    else
      ATTEMPTS=$[$ATTEMPTS+1]
      printf "${RED}ERROR::${NC} Please choose an option listed above\n"
    fi
  done
  unset chosenOption

  # Too many attempts
  if [ $ATTEMPTS -eq 3 ]; then
    printf "\nToo many attempts, quitting...\n"
    exit
  fi

  if [ $option ] && [ $option -eq 1 ]; then
    unset option
    create_stack
  fi
  if [ $option ] && [ $option -eq 3 ]; then
    exit
  fi
}

display_options