#!/bin/bash

(echo "//multiline" && cat $1 && echo "//<GO2>") | ./interpreter_mac_arm64 | bash

# Start: Reproducible build (optional)
cat <<'EOX' > go.mod
module app

go 1.23.5
EOX
export CGO_ENABLED=0
export GOOS=darwin
export GOARCH=arm64
export SOURCE_DATE_EPOCH=1609459200
go mod tidy
go build \
  -trimpath \
  -ldflags="-buildid= -X main.version=1.0.0 -w -s" \
  -o app \
  app.go
rm go.mod 
# End: Reproducible build (optional)

rm app.go
mv app $2
