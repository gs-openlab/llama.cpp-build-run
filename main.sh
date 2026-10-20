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

# Download Gemma 4 E2B GGUF Q4_0
if [ ! -f cache/gemma-4-E2B-it-Q4_0.gguf ]; then
    echo "Downloading Gemma 4 E2B GGUF Q4_0..."
    aria2c --max-connection-per-server=16 --min-split-size=1M https://modelscope.cn/models/ggml-org/gemma-4-E2B-it-GGUF/resolve/master/gemma-4-E2B-it-Q4_0.gguf -o cache/gemma-4-E2B-it-Q4_0.gguf
else
    echo "Gemma 4 E2B GGUF Q4_0 already exists, skipping download..."
fi

# Build llama.cpp for CPU and Metal backends and run llama-cli with expect
bash build.sh --cpu | tee dist/build_log.txt
expect -f chat.exp -- ./cache/llama.cpp/build/bin/llama-cli --model cache/gemma-4-E2B-it-Q4_0.gguf | tee dist/chat_log.txt
bash build.sh --metal | tee dist/build_log_metal.txt
expect -f chat.exp -- ./cache/llama.cpp/build/bin/llama-cli --model cache/gemma-4-E2B-it-Q4_0.gguf -ngl 99 | tee dist/chat_log_metal.txt

# Run llama-server in the background and call it with curl
# With llama-server running
./cache/llama.cpp/build/bin/llama-server --model cache/gemma-4-E2B-it-Q4_0.gguf -ngl 99 --port 8080 --log-file dist/inference_log.txt &
llama_server_pid=$!
trap "kill $llama_server_pid" EXIT
    ## Wait for llama-server to be ready
    while [ "$(curl -s -o /dev/null -w '%{http_code}' http://localhost:8080/v1/health)" != "200" ]; do
        sleep 1
    done
    ## Call llama-server with curl
    curl -X POST \
        -H "Content-Type: application/json" \
        -d '{"prompt":"I want to wash my car. The car wash is 50 meters away. Should I walk or drive?"}' \
        http://localhost:8080/v1/completions \
        -o dist/inference_result.txt
# Cancel the EXIT trap before killing, so the PID wont be killed twice
trap - EXIT
kill $llama_server_pid

# Quantize the model
./cache/llama.cpp/build/bin/llama-quantize --allow-requantize cache/gemma-4-E2B-it-Q4_0.gguf cache/gemma-4-E2B-it-Q2_K.gguf Q2_K
# Run quantized model
expect -f chat.exp -- ./cache/llama.cpp/build/bin/llama-cli --model cache/gemma-4-E2B-it-Q2_K.gguf -ngl 99 -n 2048 | tee dist/chat_log_q2_k.txt