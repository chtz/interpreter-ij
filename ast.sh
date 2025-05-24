#!/bin/bash

(echo "//multiline" && cat $1 && echo "//<AST>") | ./native_interpreter.sh interpreter.s
