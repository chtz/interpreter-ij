#!/bin/bash

set -e

# Detect OS
OS="$(uname -s)"
ARCH="$(uname -m)"

# Normalize OS
case "$OS" in
    Linux)   OS_NAME="linux" ;;
    Darwin)  OS_NAME="mac" ;;
    *)       echo "Unsupported OS: $OS" >&2; exit 1 ;;
esac

# Normalize ARCH
case "$ARCH" in
    x86_64)  ARCH_NAME="amd64" ;;
    arm64|aarch64) ARCH_NAME="arm64" ;;
    *)       echo "Unsupported architecture: $ARCH" >&2; exit 1 ;;
esac

# Construct binary name
BINARY="./interpreter_${OS_NAME}_${ARCH_NAME}"

# Check if the binary exists
if [[ ! -x "$BINARY" ]]; then
    echo "No suitable binary found for $OS_NAME on $ARCH_NAME." >&2
    exit 1
fi

(echo "//multiline" && cat $1 && echo "//<GO2>") | ./$BINARY | bash

# Start: Reproducible build (optional)
docker run --rm -v "$PWD":/src -w /src -e SOURCE_DATE_EPOCH=1609459200 -e GOOS=linux -e GOARCH=amd64 -e CGO_ENABLED=0 golang:1.23.5 sh -c 'go build -trimpath -ldflags="-buildid= -X main.version=1.0.0 -w -s" app.go'
# End: Reproducible build (optional)

rm app.go
mv app $2
