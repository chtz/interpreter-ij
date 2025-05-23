#!/bin/bash

# Claude Desktop Config
#{
#  "mcpServers": {
#    "ijscript": {
#      "command": "/.../mcp.sh",
#      "args": [],
#      "transport": {
#        "type": "stdio"
#      }
#    }
#  }
#}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd $SCRIPT_DIR
cat interpreter.s|./until.rb "interpreter is ready" > interpreter_base.s
cat interpreter_base.s eval.s mcp.s > mcp_eval.s
./native_interpreter.sh mcp_eval.s
