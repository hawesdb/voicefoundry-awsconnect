#!/bin/bash
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color
BOLD=$(tput bold)
NORMAL=$(tput sgr0)

CONFIG_FILE=.cloudformation-config

#####################################################
# CONFIG CHECK                                      #
#####################################################
if [ -f $CONFIG_FILE ]; then
  source $CONFIG_FILE
  if [ -z $connect_arn ] || [ -z $ecr_arn ] || [ -z $template_s3 ] || [ -z $stack_name ]; then
    printf "${RED}ERROR${NC} Run the configure.sh script to setup the project\n"
    exit
  fi
else
  printf "${RED}ERROR${NC} Run the configure.sh script to setup the project\n"
  exit
fi

#####################################################
# PRINT STATUS                                      #
#####################################################
display_status() {
  printf "Stack:  $stack_name\n"
  stack_status=$(aws cloudformation describe-stacks --stack-name $stack_name --output yaml 2> /dev/null)
  if [ $? -ne 0 ]; then
    printf "Status: ${RED}DOWN${NC}\n\n"
  else
    stack_status=$(printf "${stack_status#*StackStatus\: }" | head -1)
    status_type=$(sed 's/.*_\(.*\)/\1/' <<< $stack_status)

    if [ ${status_type^^} == 'COMPLETE' ]; then
      stack_status=${GREEN}$stack_status${NC}
    elif [ ${status_type^^} == 'PROGRESS' ]; then
      stack_status=${YELLOW}$stack_status${NC}
    else
      stack_status=${RED}$stack_status${NC}
    fi

    printf "Status: $stack_status\n\n"
  fi
}

#####################################################
# GET USER INPUT                                    #
#####################################################
get_option() {
  echo "${BOLD}Please select an option to continue:
  1. Create Cloudformation stack
  2. Update Cloudformation stack
  3. Exit${NORMAL}
  "
  attempts=0
  while [ -z $option ] && [ $attempts -lt 2 ]; do
    read -n1 -e -p "Option: " chosen_option
    if ((chosen_option >= 1 && chosen_option <= 3)); then
      option=$chosen_option
      break
    else
      ((attempts=attempts+1))
      printf "\n${RED}ERROR${NC} Please choose an option listed above\n\n"
    fi
  done
  unset chosen_option

  # Too many attempts
  if [ $attempts -eq 2 ]; then
    printf "Too many attempts! Quitting...\n"
    exit
  fi

  # create stack
  if [ $option ]; then
    if [ $option -eq 1 ]; then
      print_option="create a stack"
    elif [ $option -eq 2 ]; then
      print_option="update a stack"
    else
      exit
    fi

    read -e -p "Are you sure you want to $print_option [N/y]? " confirm_option
    if [ -z ${confirm_option} ]; then
      unset option
      printf "\n---------------------------\n\n\n\n"
      display_status
      get_option
    else
      if [ ${confirm_option,,} = "yes" ] || [ ${confirm_option,,} = "y" ]; then
        if [ $option -eq 1 ]; then
          create_stack
        elif [ $option -eq 2 ]; then
          update_stack
        fi
      elif [ ${confirm_option,,} = "no" ] || [ ${confirm_option,,} = "n" ]; then
        unset option
        printf "\n---------------------------\n\n\n\n"
        display_status
        get_option
      else
        unset option
        printf "\n${RED}ERROR${NC} Not a valid answer, taking you back\n---------------------------\n\n\n\n"
        display_status
        get_option
      fi
    fi
  fi
}

#####################################################
# CREATE_STACK                                      #
#####################################################
create_stack() {
  printf "\nChecking if stack already exists..\n"
  aws cloudformation get-stack-policy --stack-name $stack_name > /dev/null 2>&1

  if [ $? -eq 0 ]; then
    printf "Stack already exists ... taking you back to the options\n\n\n\n"
    display_status
    get_option
  else
    package_templates
    build_lambda

    printf "\n-- Creating the stack\n\n"
    aws cloudformation create-stack \
      --stack-name $stack_name \
      --parameters \
        ParameterKey=ConnectArn,ParameterValue=$connect_arn \
      --template-body file://packaged-cloudformation.yaml \
      --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND
  fi
}

#####################################################
# UPDATING_STACK                                    #
#####################################################
update_stack() {
  printf "\nChecking if stack already exists..\n"
  aws cloudformation get-stack-policy --stack-name $stack_name > /dev/null 2>&1

  if [ $? -ne 0 ]; then
    printf "Stack does not exist ... taking you back to the options\n\n\n\n"
    display_status
    get_option
  else
    package_templates
    build_lambda

    # force an update of the function code
    aws lambda update-function-code \
      --function-name VanityNumbers \
      --image-uri $ecr_arn/vanity-numbers:latest

    printf "\n-- Updating the stack\n\n"
    aws cloudformation update-stack \
      --stack-name $stack_name \
      --parameters \
        ParameterKey=ConnectArn,ParameterValue=$connect_arn \
      --template-body file://packaged-cloudformation.yaml \
      --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND
  fi
}

#####################################################
# PACKAGE TEMPLATES                                 #
#####################################################
package_templates() {
  printf "\n-- Packaging Template\n"
  aws cloudformation package \
    --s3-bucket $template_s3 \
    --template-file cloudformation.yaml \
    --output-template-file packaged-cloudformation.yaml
}

#####################################################
# BUILD LAMBDA                                      #
#####################################################
build_lambda() {
  printf "\n-- Building lambda\n\n"
  before_build_id=$(docker inspect --format {{.Id}} vanity-numbers)
  docker build -t vanity-numbers functions/vanityNumbers/.
  after_build_id=$(docker inspect --format {{.Id}} vanity-numbers)

  IMAGE_META="$( aws ecr describe-images --repository-name=vanity-numbers --image-ids=imageTag=latest 2> /dev/null )"
  # if latest tag not found or build before =/= build after
  if [ $? -ne 0 ] || [ $before_build_id != $after_build_id ]; then
    printf "\n-- Pushing new image to ECR\n\n"
    docker tag vanity-numbers:latest $ecr_arn/vanity-numbers:latest
    docker push $ecr_arn/vanity-numbers:latest
  fi
}

#####################################################
# MAIN                                              #
#####################################################
echo "
#---------------------------------------------------#
# DEPLOYMENT                                        #
# --------------------------------------------------#
"
display_status
get_option