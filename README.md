# README
Assuming you have
* `kii-dev` profile
* `terraform`


## shell script runs on lambda
One of lambda functions is deployed as custom runtime runs on AmazonLinux2.
The response is returned by a shell script, `./functions/bash/function.sh`.

```bash
[0]$ aws --profile kii-dev logs tail --follow /aws/lambda/issue8432-custom
...
```
```
[1]$ aws --profile kii-dev lambda invoke output.txt \
	         --cli-binary-format raw-in-base64-out \
	         --function-name issue8432-custom \
	         --payload '{"commands":[ \
	                        "curl https://checkip.amazonaws.com", \
			        "ls / | head -3", \
			        "echo 'hello'" \
			      ]}' \
	         && cat output.txt
{
    "StatusCode": 200,
    "ExecutedVersion": "$LATEST"
}
54.178.235.198  # the response of the curl
bin             # ls /
boot            #
dev             #
hello           # output of the echo
```
