#!/bin/bash

(echo "//multiline" && cat $1 && echo "//<EOF>" && cat) | ./native_interpreter.sh interpreter.s
