package main

import (
	"context"
	"fmt"
	"log"

	"github.com/aws/aws-lambda-go/lambda"
)

type MyEvent struct {
	Name string `json:"name"`
}

var (
	BuiltAt string
	Commit  string
)

func HandleRequest(ctx context.Context, name MyEvent) (string, error) {
	log.Printf("commit:%v, built-at:%v", Commit, BuiltAt)
	log.Printf("ctx:%v, event:%v", ctx, name)
	return fmt.Sprintf("Hello %s!", name), nil
}

func main() {
	lambda.Start(HandleRequest)
}
