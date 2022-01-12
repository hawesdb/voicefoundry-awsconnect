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
# ZIP ALL LAMBDAS                                   #
#####################################################
upload_lambdas () {
  printf "uploading lambdas"
  docker build -t vanity-numbers functions/vanityNumbers/.
  docker tag vanity-numbers:latest 859530432683.dkr.ecr.us-east-1.amazonaws.com/vanity-numbers:latest
  docker push 859530432683.dkr.ecr.us-east-1.amazonaws.com/vanity-numbers:latest
  DOCKERSHA=$(docker images --no-trunc --quiet 859530432683.dkr.ecr.us-east-1.amazonaws.com/vanity-numbers:latest)
  # python -m venv python-packages
  # source python-packages/Scripts/activate
  # python -m pip install --upgrade pip
  # pip install nltk -t functions/vanityNumbers
  # pip install regex==2019.11.1 -t functions/vanityNumbers --force-reinstall
  # deactivate
  # # cp -r python-packages/Lib/site-packages/joblib functions/vanityNumbers/
  # # cp -r python-packages/Lib/site-packages/regex functions/vanityNumbers/
  # # cp -r python-packages/Lib/site-packages/colorama functions/vanityNumbers/
  # # cp -r python-packages/Lib/site-packages/click functions/vanityNumbers/
  # # cp -r python-packages/Lib/site-packages/tqdm functions/vanityNumbers/
  # # cp -r python-packages/Lib/site-packages/nltk functions/vanityNumbers/
  # aws cloudformation package \
  # --template cloudformation.yaml \
  # --s3-bucket hawesdb-voicefoundry-lambdas \
  # --output-template-file packaged-cloudformation.yaml
}
# build_lambdas () {
#   cd functions
#   for filename in *; do
#     if [ -d $filename/ ]; then
#       if [ -d $filename/$filename.zip ]; then
#         rm $filename/$filename.zip
#       fi
#       jar -cMf $filename/$filename.zip $filename/
#     else
#       if [[ $filename != *.zip ]]; then
#         if [ -d $filename.zip ]; then
#           rm $filename.zip
#         fi
#         jar -cMf ${filename%.*}.zip $filename
#       fi
#     fi
#   done
#   cd ..
# }

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
    upload_lambdas
    aws cloudformation create-stack \
    --stack-name $STACKNAME \
    --parameters \
      ParameterKey=ConnectArn,ParameterValue=$CONNECTARN \
      ParameterKey=DockerSHA,ParameterValue=$DOCKERSHA \
    --template-body file://cloudformation.yaml \
    --capabilities CAPABILITY_IAM
  fi
}

#####################################################
# UPDATE STACK FUNCTION                             #
#####################################################
update_stack () {
  printf "\nChecking if stack already exists..\n\n"
  aws cloudformation get-stack-policy --stack-name $STACKNAME > /dev/null 2>&1

  if [ $? -ne 0 ]; then
    printf "Stack does not exist ... taking you back to the options\n\n"
    display_options
  else
    upload_lambdas
    aws lambda update-function-code --function-name VanityNumbers --image-uri 859530432683.dkr.ecr.us-east-1.amazonaws.com/vanity-numbers:latest
    aws cloudformation update-stack \
    --stack-name $STACKNAME \
    --parameters \
      ParameterKey=ConnectArn,ParameterValue=$CONNECTARN \
      ParameterKey=DockerSHA,ParameterValue=$DOCKERSHA \
    --template-body file://cloudformation.yaml \
    --capabilities CAPABILITY_IAM
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
  elif [ $option ] && [ $option -eq 2 ]; then
    unset option
    update_stack
  elif [ $option ] && [ $option -eq 3 ]; then
    exit
  else
    exit
  fi
}

display_options