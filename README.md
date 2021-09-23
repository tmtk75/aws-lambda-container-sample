# README
This repository provides examples for some interesting use-cases for AWS Lambda as CloudWatch Logs is event source.
* Process logs with lambda function directly.
* Transfer events in CloudWatch Logs to S3 bucket thru Kinesis Firehose processing its events with lambda function.
* Custom runtime with Amazon Linux2 to run shell script though container.

All resources can be deployed with terraform.
You can try the use-cases in a few minutes if.

Assuming you have
* an AWS account you can create IAM roles.
* some commands, terraform, jq, docker and awscli.


## Getting Started
### Deployment
```bash
# Make an ECR repository.
$ terraform apply --auto-approve -target aws_ecr_repository.main
...

# Build images.
# This may take a few minutes more to build an image for nodejs
$ make build-nodejs
...

# Push images.
$ ./main.sh docker-login
$ ./main.sh push nodejs

# Deploy the rest.
$ terraform apply --auto-approve 
...
```

```bash
# Update cache.
$ make
...
```

> error creating Lambda Function (1): InvalidParameterValueException: Source image
If you see this error, the image is not ready. Check the ECR repository.


### Scenario: propagation to s3 bucket thru firehose
```bash
# Start tailing log of main lambda
[0]$ ./main.sh tail

[1]$ ./main.sh invoke
{
    "StatusCode": 200,
    "ExecutedVersion": "$LATEST"
}
"2021/09/12/[$LATEST]db78f61565b64fe7b939f080b03dc90b"
```
You will see some logs in the termianl [0].

Wait for an object is created. It usually took about 2 minutes when I tried.
```bash
# Wait for an object is created.
[0]$ while true; do ./main.sh ls-s3 ; echo -- ; sleep 3; done
...
--
2021-09-12 22:03:26        218 fh/2021/09/12/13/<YOUR-PREFIX>to-s3bucket-1-2021-09-12-13-01-55-c7c54702-4d79-40ff-90cd-ff3b1f56d852

# You can see a created s3 object.
[0] $ key=fh/2021/09/12/13/<YOUR-PREFIX>to-s3bucket-1-2021-09-12-13-01-55-c7c54702-4d79-40ff-90cd-ff3b1f56d852
[0] $ ./main.sh cp-s3 ${key} | gzip -d | jq .
{
  "messageType": "DATA_MESSAGE",
  ...
  "logEvents": [
    {
      "id": "36382640181000760296772246317297082294490083963235205120",
    ...
  ],
  "message": "processed successfully"
}
```
The last top level field, `"message"`, is added by the processor.


### Scenario: lambda subscribing log group
```bash
# You can see decoded event in a log group.
[0]$ ./main.sh tail subscribe
... received log events: {"messageType":"DATA_MESSAGE","...
```


### Scenario: shell script runs on lambda
One of lambda functions is deployed as custom runtime runs on AmazonLinux2.
The response is returned by a shell script, `./functions/bash/function.sh`.
```bash
[0]$ ./main.sh tail custom
...

[1]$ ./main.sh invoke-custom '{}'
{
    "StatusCode": 200,
    "ExecutedVersion": "$LATEST"
}
Echoing request: '{}'
...
```


## Update lambda functions
If you update lambda function, you need `update-function-code` not only pushing images.
```bash
$ make build-nodejs
...
$ ./main.sh push nodejs
...
# If you want to update `processor`.
$ ./main.sh update-func processor nodejs
...
```

## Test on RIE
AWS supports RIE (Runtime Interface Environment).
We can test container image for lambda locally.
```
[0]$ make rie-nodejs
...

[1]$ make run-test
...
```

## Other runtimes
nodejs is used for the above scenarios.

This repository provides other major runtimes as example.
* Python
* Golang
* Java

```bash
$ make build-python
...

# Push 
$ ./main.sh push python
...
$ ./main.sh update-func main python
...

# You can see a different response from function runs on nodejs.
$ ./main.sh invoke
{
    "StatusCode": 200,
    "ExecutedVersion": "$LATEST"
}
"Hello from AWS Lambda using Python3...
```


## Destroy
Clean up all s3 objects in the bucket first and destroy with terraform.
```
$ ./main.sh cleanup-s3
...

$ terraform destroy
...
Enter a value: yes
```

## TODO
* Dynamic partitioning if terraform supports
