#!/bin/bash
# Local-Go variant of compile-mac.sh. No Docker.
# Uses the already-installed `go` toolchain. set -e aborts on any step failure
# so callers get a real exit code (unlike the Docker version which silently
# skipped the go build step on this host).
#
# Usage: ./compile-local.sh <source.s> <output-binary>

set -e

OS="$(uname -s)"
ARCH="$(uname -m)"
case "$OS" in
    Linux)   OS_NAME="linux" ;;
    Darwin)  OS_NAME="mac" ;;
    *)       echo "Unsupported OS: $OS" >&2; exit 1 ;;
esac
case "$ARCH" in
    x86_64)  ARCH_NAME="amd64" ;;
    arm64|aarch64) ARCH_NAME="arm64" ;;
    *)       echo "Unsupported architecture: $ARCH" >&2; exit 1 ;;
esac

BINARY="./interpreter_${OS_NAME}_${ARCH_NAME}"
if [[ ! -x "$BINARY" ]]; then
    echo "No suitable binary found for $OS_NAME on $ARCH_NAME." >&2
    exit 1
fi

if ! command -v go >/dev/null 2>&1; then
    echo "go not in PATH; install Go or use compile-mac.sh/compile-linux.sh" >&2
    exit 1
fi

src="$1"
out="$2"
if [[ -z "$src" || -z "$out" ]]; then
    echo "usage: $0 <source.s> <output-binary>" >&2
    exit 2
fi

# Transpile IJ -> Go. Tee the transpile stderr so that a crash is visible.
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT
(echo "//multiline" && cat "$src" && echo "//<GO2>") | "$BINARY" > "$tmpdir/gen.sh" 2> "$tmpdir/gen.err"
rc=${PIPESTATUS[1]}
if [[ $rc -ne 0 ]]; then
    echo "transpile failed (exit=$rc):" >&2
    tail -20 "$tmpdir/gen.err" >&2
    exit $rc
fi

# The transpiler emits a shell script that writes app.go. Run it here.
bash "$tmpdir/gen.sh"

# Build natively with local Go, matching the docker flags.
GOARCH="$ARCH_NAME" GOOS="$( [[ $OS_NAME == mac ]] && echo darwin || echo $OS_NAME )" CGO_ENABLED=0 \
    go build -trimpath -ldflags="-buildid= -X main.version=1.0.0 -w -s" -o "$out" app.go

rm -f app.go
