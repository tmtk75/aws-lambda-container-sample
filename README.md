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
			        "ls / | head -3"
			      ]}' \
	         && cat output.txt
{
    "StatusCode": 200,
    "ExecutedVersion": "$LATEST"
}
54.178.235.198  # the response of the curl. Internet accessible.
bin             # ls /
boot            #    Amazon Linux FS is seen.
dev             #
```

## Layout
```
.
|-- Makefile
|-- README.md
|-- functions
|   |-- bash
|   |   `-- function.sh
|   `-- bash.zip
|-- layers
|   |-- bash
|   |   |-- Makefile
|   |   |-- README.md
|   |   |-- bin
|   |   |   `-- jq
|   |   `-- bootstrap
|   `-- bash.zip
|-- main.tf
|-- modules
|   |-- common
|   |   |-- main.tf
|   |   |-- outputs.tf
|   |   `-- variables.tf
|   `-- custom-runtime
|       |-- main.tf
|       |-- outputs.tf
|       `-- variables.tf
|-- my.auto.tfvars
|-- outputs.tf
`-- variables.tf
```
