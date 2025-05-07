#!/bin/bash

(echo "//multiline" && cat $1 && echo "//<EOF>" && cat) | ./interpreter_mac_arm64
