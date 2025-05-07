#!/bin/bash

(echo "//multiline" && cat $1 && echo "//<GO2>") | ./interpreter_mac_arm64 | bash
mv app $2
rm app.go
