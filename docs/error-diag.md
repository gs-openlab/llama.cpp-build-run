## 错误信息
> -- UI: download dist.tar.gz.sha256 from b11723 failed: "Timeout was reached"
> -- UI: downloading from latest: https://huggingface.co/buckets/ggml-org/llama-ui/resolve/latest/dist.tar.gz
> -- UI: download dist.tar.gz.sha256 from latest failed: "Timeout was reached"
> -- UI: HF download failed
> CMake Warning at /Users/bcw/Documents/Personal/Projects/gs-openlab/llama.cpp-build-run/cache/llama.cpp/scripts/ui-assets.cmake:584 (message):
>   UI: no assets available - building without an embedded UI.  In a
>   disconnected environment, download the pre-built UI from a llama.cpp
>   release at https://github.com/ggml-org/llama.cpp/releases and extract to
>   tools/ui/dist.
> 
> 
> -- UI: embedded 0 assets
> [  4%] Built target llama-ui-assets
> make: *** [all] Error 2

## 问题定位
读取错误信息，发现问题出现在网络获取超时（failed: "Timeout was reached"）
读取网络获取源，结合常识，判断问题在于 huggingface.co 不可达

## 解决方案
1. 将 llama.cpp pin 到特定版本（取发现问题时的最新 master 31288c9c66e59377f7788d920678a565bb89dd37）
2. 将 huggingface.co 改为优先读取 $HF_ENDPOINT
3. 将更改保存为 patch ，并在脚本中添加自动应用逻辑