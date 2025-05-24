#!/bin/bash

(echo "//multiline" && cat $1 && echo "//<AST>" && cat) | ./native_interpreter.sh interpreter.s
