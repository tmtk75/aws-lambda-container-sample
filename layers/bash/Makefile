build: bin/jq

./bin:
	mkdir -p bin

bin/jq: ./bin
	curl -s -o ./bin/jq -OL \
		https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 \
	&& chmod +x ./bin/jq


