#!/bin/bash
# Benchmark the self-hosted interpreter and the native interpreter test run.
# Usage: ./bench.sh [label]
# Appends timings to bench.log.

set -e

LABEL="${1:-run}"
LOG="bench.log"
STAMP="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

{
  echo "=== $STAMP label=$LABEL ==="
  echo "-- selfhosted_interpreter.sh sample.s (stdin=hi) --"
  { time (echo "hi" | ./selfhosted_interpreter.sh sample.s >/dev/null); } 2>&1
  echo "-- interpreter.sh test.s --"
  { time (echo | ./interpreter.sh test.s >/dev/null); } 2>&1
  echo "-- native_interpreter.sh test.s --"
  { time (echo | ./native_interpreter.sh test.s >/dev/null); } 2>&1
  echo
} | tee -a "$LOG"
