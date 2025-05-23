#!/bin/bash
cd /Users/chrigi/git/interpreter-ij
cat interpreter.s|./until.rb "interpreter is ready" > interpreter_base.s
cat interpreter_base.s eval.s mcp.s > mcp_eval.s
./native_interpreter.sh mcp_eval.s
