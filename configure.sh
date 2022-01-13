#!/bin/bash
RED='\033[1;31m'
NC='\033[0m' # No Color

CONFIG_FILE=.cloudformation-config
MAX_ATTEMPTS=2

default_connect_arn=''
default_ecr_arn=''
default_stack_name='voicefoundry'

#####################################################
# PRINT HEADER                                      #
#####################################################
cat << EOF

#---------------------------------------------------#
#                  Setup Script                     #
#---------------------------------------------------#

EOF

#####################################################
# CHECK INSTALLS                                    #
#####################################################
install_flags=0
if [ ! -x "$(command -v aws)" ]; then
  printf "${RED}ERROR${NC} Please install AWS\n"
  ((install_flags=install_flags+1))
fi
if [ ! -x "$(command -v docker)" ]; then
  printf "${RED}ERROR${NC} Please install Docker\n"
  ((install_flags=install_flags+1))
fi

if [ $install_flags -gt 0 ]; then
  exit
fi

#####################################################
# AWS ACCESS KEY                                    #
#####################################################
aws configure

#####################################################
# REPOPULATE FROM CONFIG FILE                       #
#####################################################
printf "\nChecking if config file has already been populated\n\n"
if [ -f $CONFIG_FILE ]; then
  source $CONFIG_FILE
  if [ $connect_arn ]; then
    default_connect_arn=$connect_arn
  fi
  if [ $ecr_arn ]; then
    default_ecr_arn=$ecr_arn
  fi
  if [ $stack_name ]; then
    default_stack_name=$stack_name
  fi
fi

#####################################################
# GET USER INPUT                                    #
#####################################################
attempts=0
while [ $attempts -lt 2 ] && [ -z $new_connect_arn ]; do
  [[ -z $default_connect_arn ]] && print_connect_arn="NONE" || print_connect_arn=$default_connect_arn
  read -e -p "Connect Instance ARN[$print_connect_arn]: " new_connect_arn
  # No input and no default
  if [ -z $new_connect_arn ] && [ -z $default_connect_arn ]; then
    ((attempts=attempts+1))
    printf "${RED}ERROR${NC} Please input an instance ARN\n\n"
  # no input but default found
  elif [ -z $new_connect_arn ] && [ -n $default_connect_arn ]; then
    new_connect_arn=$default_connect_arn
  fi
done

attempts=0
while [ $attempts -lt $MAX_ATTEMPTS ] && [ -z $new_ecr_arn ]; do
  [[ -z $default_ecr_arn ]] && print_ecr_arn="NONE" || print_ecr_arn=$default_ecr_arn
  read -e -p "Elastic Container Repository ARN[$print_ecr_arn]: " new_ecr_arn
  # No input and no default
  if [ -z $new_ecr_arn ] && [ -z $default_ecr_arn ]; then
    ((attempts=attempts+1))
    printf "${RED}ERROR${NC} Please input a repository ARN\n\n"
  # no input but default found
  elif [ -z $new_ecr_arn ] && [ -n $default_ecr_arn ]; then
    new_ecr_arn=$default_ecr_arn
  fi
done

# break out of config
if [ $attempts -eq $MAX_ATTEMPTS ]; then
  printf "too many attempts! Quitting...\n"
  exit
fi

read -e -p "Stack Name[${default_stack_name}]: " new_stack_name
if [ -z $new_stack_name ]; then
  new_stack_name=$default_stack_name
fi

#####################################################
# AUTHORIZE ECR UPLOADS                             #
#####################################################
printf "\nAuthorizing User to upload to ECR\n"
aws ecr get-login-password --region $(aws configure get region) | docker login --username AWS --password-stdin ${new_ecr_arn}

#####################################################
# UPDATING CONFIG FILE                              #
#####################################################
printf "\nUpdating config file...\n"
if [ ! -f $CONFIG_FILE ]; then
  touch $CONFIG_FILE
fi
echo "connect_arn=$new_connect_arn" > $CONFIG_FILE
echo "ecr_arn=$new_ecr_arn" >> $CONFIG_FILE
echo "stack_name=$new_stack_name" >> $CONFIG_FILE