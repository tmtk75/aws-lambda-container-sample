#
#
#
RUNTIME := nodejs
IMAGE_NAME := myfunc:$(RUNTIME)
ENTRY_NAME := /hello
RIE_DIR := .aws-rie

.DEFAULT_GOAL := .outputs.cache

#
.outputs.cache: terraform.tfstate
	terraform output --json > .outputs.cache

#
# nodejs
#
rie-nodejs:
	docker run -p 9000:8080 myfunc:nodejs

build-nodejs:
	cd functions/nodejs; make build

#
# python
#
rie-python:
	docker run -p 9000:8080 myfunc:python

build-python:
	cd functions/python; make build

#
# golang
#
run-rie-golang: ./.aws-rie/aws-lambda-rie
	docker run -v `pwd`/$(RIE_DIR):/aws-lambda --entrypoint /aws-lambda/aws-lambda-rie -p 9000:8080 $(IMAGE_NAME) $(ENTRY_NAME)

./.aws-rie/aws-lambda-rie:
	mkdir -p $(RIE_DIR)
	curl -s -Lo $(RIE_DIR)/aws-lambda-rie https://github.com/aws/aws-lambda-runtime-interface-emulator/releases/latest/download/aws-lambda-rie
	chmod +x $(RIE_DIR)/aws-lambda-rie

build-golang:
	cd functions/golang; make build

#
# java
#
rie-java:
	docker run -p 9000:8080 myfunc:java

build-java:
	cd functions/java; make build

#
# custom
#   ./main.sh update-func-custom && ./main.sh invoke-custom
#
build-custom: build-layer-bash
build-layer-bash:
	cd layers/bash; make build

#
# test locally
#
run-test:
	curl -XPOST "http://localhost:9000/2015-03-31/functions/function/invocations" -d '{"name":"'${USER}'"}'

clean:
	cd functions/java; make clean
	rm -rf .aws-rie output.json


.PHONY: run-test
.PHONY: build-golang rie-golang
.PHONY: build-nodejs rie-nodejs
.PHONY: build-python rie-python
.PHONY: build-java rie-java
