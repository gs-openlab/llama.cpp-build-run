#!/bin/bash
set -euo pipefail

# Create dist directory if it doesn't exist
mkdir -p dist

# Clone llama.cpp repo
if [ ! -d cache/llama.cpp ]; then
    echo "Cloning llama.cpp repo..."
    git clone https://github.com/ggml-org/llama.cpp cache/llama.cpp
else
    echo "llama.cpp repo already exists, skipping clone"
fi
# With working directory set to llama.cpp repo
cd cache/llama.cpp
    git reset --hard 31288c9c66e59377f7788d920678a565bb89dd37

    # Apply patches
    for patch in ../../patches/*.patch; do
        echo "Applying patch $patch..."
        git apply "$patch"
    done
cd ../..

# Build llama.cpp for CPU and Metal backends
bash build.sh --cpu | tee dist/build_log.txt
bash build.sh --metal | tee dist/build_log_metal.txt
