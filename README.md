# voicefoundry-awsconnect
An AWS Connect repo for conversion of phone numbers to vanity numbers. Call `(323) 924-6194` to test it out!

## Setup
I have created a few scripts to speed up the deployment of the application, but some steps to be done first

### Downloads
- AWS CLI https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html
- Docker https://docs.docker.com/get-docker/

### AWS
- Create an Access Key for the user https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html
  - Make sure to download and store safely in case you need to view it again
- <b>[ Connect ]</b> This cannot be made through Cloudformation, create an instance of it and keep it's `Instance ARN` handy, the configure script needs it
- <b>[ Elastic Container Repository (ECR) ]</b> Going to be used to store the lambda images, due to my decision to package up the lambdas and pushing them up before deploying the cloudformation. Create this beforehand and give it the name of `vanity-numbers`, keep the `ARN` handy, what comes before vanity-numbers in the `URI` as we will need this for the configure script as well
- <b>[ S3 ] </b> Because we split up the cloudformation template, the `package` command will store the non main YAML files in this bucket, just create this bucket and save the name given to it

## Configure
```
configure.sh
```
After gathering this material, we can run the `configure.sh` script. this will perform 3 main steps:
1. Run `aws configure` which you will fill in with your access key and region
2. Fill in the additional AWS names we saved in a configuration file to make it easy to perform updates later.
3. Log in the user so that they can perform uploads to the ECR

After running this script, you shouldn't need to run it again unless you want to change the data or are setting up on a new computer

## Deploy
```
deploy.sh
```
You can now run the `deploy.sh` script! You can make decisions during it's runtime whether you want to create the stack or update the stack. Almost everything should be setup then.

## Contact Flow Attachment
Unfortunately the lambda and contact flow cannot be attached fully to a phone number directly through cloudformation. After the flow has been created, 2 things must happen:
1. head to `Amazon Connect -> (click on Instance Alias) -> Contact Flows -> (scroll down to the AWS Lambda section) -> (click on the Lambda drop down) -> Select the Vanity Number Lambda -> Add Lambda Function`. This has now made it so your contact flow can access the lambda
2. head to `Amazon Connect -> (click on Instance Alias) -> (Click on the Access URL in Account Overview) -> (Login) -> Routing -> Phone Numbers -> Claim a Number -> DID (Direct Inward Dialing) -> Select a Number -> (scroll down to Optional Information) -> (Click on the Contact Flow / IVR dropdown) -> Select the Contact Flow -> Save`

## ISSUES
- After connecting a contact flow, you cannot fully delete the cloudformation stack as it has been attached to a phone number. If you need to recreate the cloudformation stack, you must switch the contact flow associated with the phone number first
- If you do delete a cloudformation stack, you must perform the first step of the Contact Flow Attachment section again. Remove the lambda currently associated and reattach it
- It seems the first call to the number will always give the user a hangup, but the function still calls. Calling the number again will work