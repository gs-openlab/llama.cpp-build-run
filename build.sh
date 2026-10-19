#!/bin/bash
set -euo pipefail

# Parse arguments
usage() {
    echo "Usage: $0 <--cpu|--metal>" >&2
    exit 1
}

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $(basename "$0"): $*" >&2
}

backend=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --cpu)   [[ -n "$backend" ]] && { echo "Error: 只能选一个" >&2; exit 1; }; backend="cpu"   ; shift ;;
        --metal) [[ -n "$backend" ]] && { echo "Error: 只能选一个" >&2; exit 1; }; backend="metal" ; shift ;;
        -h|--help) usage ;;
        *) echo "Unknown option: $1" >&2 ; usage ;;
    esac
done

# Sanity check
[[ -z "$backend" ]] && { echo "Error: 必须指定 --cpu 或 --metal" >&2; exit 1; }
[ "$(uname -s)" != "Darwin" ] && echo "Error: 仅支持 macOS" >&2 && exit 1

log "backend = $backend"

# Set working directory to llama.cpp repo
cd cache/llama.cpp

# Build llama.cpp
case "$backend" in
    cpu)   cmake -B build -DGGML_METAL=OFF ;;
    metal) cmake -B build ;;
esac

## Cross-platform CPU count
if command -v nproc &>/dev/null; then
    CPU_COUNT=$(nproc)
elif command -v sysctl &>/dev/null; then
    CPU_COUNT=$(sysctl -n hw.ncpu)
else
    CPU_COUNT=4
fi

cmake --build build --config Release -j $CPU_COUNT

