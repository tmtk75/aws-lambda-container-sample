.DEFAULT_GOAL := build-custom

build-custom: build-layer-bash

build-layer-bash:
	cd layers/bash; make build

clean:
	rm -rf output

tail:
	aws --profile kii-dev logs tail --follow /aws/lambda/issue8432-custom

run:
	aws --profile kii-dev lambda invoke output.txt \
	         --cli-binary-format raw-in-base64-out \
	         --function-name issue8432-custom \
	         --payload '{"commands":[ \
	                        "curl https://checkip.amazonaws.com", \
			        "ls / | head -3", \
			        "echo 'hello'" \
			      ]}' \
	         && cat output.txt

