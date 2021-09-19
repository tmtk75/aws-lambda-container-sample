apache-maven-3.8.2/bin/mvn: apache-maven-3.8.2-bin.tar.gz
	tar xvfz apache-maven-3.8.2-bin.tar.gz
	touch apache-maven-3.8.2/bin/mvn

apache-maven-3.8.2-bin.tar.gz:
	curl -s -LO https://ftp.yz.yamagata-u.ac.jp/pub/network/apache/maven/maven-3/3.8.2/binaries/apache-maven-3.8.2-bin.tar.gz

build: target/myfunc-0.1.0.jar
	docker build -t myfunc:java .

target/myfunc-0.1.0.jar: src/main/java/example/Handler.java apache-maven-3.8.2/bin/mvn
	./apache-maven-3.8.2/bin/mvn package

clean:
	rm -rf apache-maven-3.8.2* target 
