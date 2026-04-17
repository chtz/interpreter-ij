#!/bin/bash
# 5-check regression harness for the C/D performance phases.
# Assumes golden outputs exist at /tmp/ij-golden/ (run `./verify.sh --capture` once to create).
#
# Usage:
#   ./verify.sh           -> run all 5 checks against current binaries
#   ./verify.sh --capture -> capture golden outputs from current binaries
#
# Exits non-zero on any regression.

set -u
GOLDEN=/tmp/ij-golden
MCP_INPUT='{"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"x","version":"1"}},"jsonrpc":"2.0","id":0}
{"method":"tools/call","params":{"name":"execute_script","arguments":{"script":"puts(1+22/7.0)"}},"jsonrpc":"2.0","id":1}
{"method":"tools/call","params":{"name":"parse_script","arguments":{"script":"puts(1+22/7.0)"}},"jsonrpc":"2.0","id":2}'

if [[ "${1:-}" == "--capture" ]]; then
    mkdir -p "$GOLDEN"
    echo | ./interpreter.sh test.s > "$GOLDEN/test.out" 2>&1
    echo hi | ./native_interpreter.sh sample.s > "$GOLDEN/sample.out" 2>&1
    echo "$MCP_INPUT" | ./mcp.sh 2>/dev/null > "$GOLDEN/mcp-interp.out"
    echo "$MCP_INPUT" | ./native_mcp.sh 2>/dev/null > "$GOLDEN/mcp-native.out"
    echo "captured goldens:"
    wc -l "$GOLDEN"/*.out
    exit 0
fi

fail=0
pass=0
note() { echo "[verify] $*"; }
ok()   { echo "  PASS: $*"; pass=$((pass+1)); }
bad()  { echo "  FAIL: $*"; fail=$((fail+1)); }

# 1. test.s interpreted -> all tests pass, byte-identical to golden.
note "1/5 test.s (interpreted)"
tmp=$(mktemp)
echo | ./interpreter.sh test.s > "$tmp" 2>&1
rc=$?
if [[ $rc -ne 0 ]]; then bad "interpreter.sh test.s exit=$rc"
elif grep -E -iq 'fail|panic|error' "$tmp"; then bad "test.s output contains fail/panic/error"; grep -E -i 'fail|panic|error' "$tmp" | head -3
elif ! diff -q "$GOLDEN/test.out" "$tmp" >/dev/null; then bad "test.s output diverges from golden"; diff "$GOLDEN/test.out" "$tmp" | head -20
else ok "test.s matches golden"; fi
rm -f "$tmp"

# 2. test.s self-hosted -> same output.
note "2/5 test.s (self-hosted)"
tmp=$(mktemp)
echo | ./selfhosted_interpreter.sh test.s > "$tmp" 2>&1
rc=$?
if [[ $rc -ne 0 ]]; then bad "selfhosted_interpreter.sh test.s exit=$rc"
elif ! diff -q "$GOLDEN/test.out" "$tmp" >/dev/null; then bad "self-hosted test.s diverges"; diff "$GOLDEN/test.out" "$tmp" | head -20
else ok "self-hosted test.s matches golden"; fi
rm -f "$tmp"

# 3. sample.s self-hosted (the real perf target).
note "3/5 sample.s (self-hosted)"
tmp=$(mktemp)
echo hi | ./selfhosted_interpreter.sh sample.s > "$tmp" 2>&1
rc=$?
if [[ $rc -ne 0 ]]; then bad "selfhosted sample.s exit=$rc"; head -5 "$tmp"
elif ! diff -q "$GOLDEN/sample.out" "$tmp" >/dev/null; then bad "self-hosted sample.s diverges"; diff "$GOLDEN/sample.out" "$tmp" | head -20
else ok "self-hosted sample.s matches golden"; fi
rm -f "$tmp"

# 4. MCP native vs golden (both interpreted and native should still match).
note "4/5 MCP native"
tmp=$(mktemp)
echo "$MCP_INPUT" | ./native_mcp.sh 2>/dev/null > "$tmp"
if ! diff -q "$GOLDEN/mcp-native.out" "$tmp" >/dev/null; then bad "native MCP diverges from golden"; diff "$GOLDEN/mcp-native.out" "$tmp" | head -10
else ok "native MCP matches golden"; fi
rm -f "$tmp"

# 5. Double self-transpile fixed point: interpreter.s -> Xa -> Xb, compare.
note "5/5 double self-transpile fixed-point"
if ./compile-local.sh interpreter.s /tmp/ij-golden/_roundtrip_a >/tmp/rt1.log 2>&1 \
   && ./compile-local.sh interpreter.s /tmp/ij-golden/_roundtrip_b >/tmp/rt2.log 2>&1; then
    if diff -q /tmp/ij-golden/_roundtrip_a /tmp/ij-golden/_roundtrip_b >/dev/null; then
        ok "binaries are bit-identical"
    else
        bad "binaries differ across transpiles: $(wc -c </tmp/ij-golden/_roundtrip_a) vs $(wc -c </tmp/ij-golden/_roundtrip_b)"
    fi
else
    bad "compile-local.sh failed"
    tail -5 /tmp/rt2.log 2>/dev/null
fi

echo "[verify] $pass pass, $fail fail"
exit $fail
