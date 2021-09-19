FROM golang:1.17 AS golang

WORKDIR /
COPY main.go go.mod go.sum /
RUN go mod download
ARG COMMIT
ARG BUILT_AT
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
      go build -a -installsuffix cgo \
        -ldflags "-X main.Commit=${COMMIT} -X main.BuiltAt=${BUILT_AT}" \
        -o hello \
        main.go


FROM busybox
#FROM alpine
COPY --from=golang /hello /
RUN chmod +x /hello

CMD ["/hello"]

# https://docs.aws.amazon.com/ja_jp/lambda/latest/dg/go-image.html#go-image-al
#ADD https://github.com/aws/aws-lambda-runtime-interface-emulator/releases/latest/download/aws-lambda-rie /usr/bin/aws-lambda-rie
#RUN chmod 755 /usr/bin/aws-lambda-rie
#COPY entry.sh /
#RUN chmod 755 /entry.sh
#ENTRYPOINT [ "/entry.sh" ]
