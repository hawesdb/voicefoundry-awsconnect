# voicefoundry-awsconnect
An AWS Connect repo for conversion of phone numbers to vanity numbers

## Setup
- Get the AWS CLI installed https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html
- Create an Access Key for the user https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html
  - Make sure to download and store safely in case you need to view it again
- Run `aws configure`
- Input the Access Key ID and Secret Access Key respectively when asked (from file just saved)
- set the region (ex: `us-east-1`)
- set the output format (ex: `json`, `yaml`)

## Cloudformation
Cloudformation works by uploading a stack, or declaration of the resources to be created.
- Create and upload the cloudformation stack with:
```
aws cloudformation create-stack \
--stack-name <name> \
--template-body file://cloudformation.yaml
```
- If you want to make changes to the stack later, use `update-stack` instead
