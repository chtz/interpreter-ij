#!/bin/bash

(echo "//multiline" && cat $1 && echo "//<GO2>") | ./interpreter_mac_arm64 | bash

# Start: Reproducible build (optional)
docker run --rm -v "$PWD":/src -w /src -e SOURCE_DATE_EPOCH=1609459200 -e GOOS=linux -e GOARCH=amd64 -e CGO_ENABLED=0 golang:1.23.5 sh -c 'go build -trimpath -ldflags="-buildid= -X main.version=1.0.0 -w -s" app.go'
# End: Reproducible build (optional)

rm app.go
mv app $2
