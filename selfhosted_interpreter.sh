#!/bin/bash

(echo "//multiline" && cat $1 && echo "//<EOF>" && cat) | ./interpreter.sh interpreter.s
