COMMIT := `git rev-parse HEAD`
BUILT_AT := `date -u +%Y-%m-%dT%H:%M:%SZ`

.DEFAULT_GOAL := build

build: build-with-docker

build-with-pack:
	pack build myfunc:golang \
	  --env "GOOGLE_GOLDFLAGS=-X main.Commit=${COMMIT} -X main.BuiltAt=${BUILT_AT}" \
	  --builder gcr.io/buildpacks/builder

build-with-docker:
	docker build . \
	  --build-arg COMMIT=$(COMMIT) \
	  --build-arg BUILT_AT=$(BUILT_AT) \
	  -t myfunc:golang

#build-with-aws-image: aws-go1.x
#aws-go1.x:
#	git clone --branch go1.x --no-tags --depth 1 https://github.com/aws/aws-lambda-base-images.git aws-go1.x

.PHONY: build-with-pack build-with-docker
