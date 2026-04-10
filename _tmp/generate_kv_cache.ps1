$slug = "kv_cache"
$prompts = @(
    "You are Ibn Haytham (Science domain agent). Write a 1000-word section on 'Introduction to KV Caches and AI Hardware Architecture'. Focus on the fundamental bottleneck of LLM inference: memory bandwidth vs compute, introduce what KV Cache is and why hardware architectures matter. Include Mermaid diagrams and tables. Write the raw markdown output directly to E:\De Anima\_tmp\kv_cache_chunk_01.md",
    "You are Ibn Haytham (Science domain agent). Write a 1000-word section on 'The Anatomy of the KV Cache'. Deep dive into Key-Value caching mechanism, how it stores past context, memory footprint calculations for large contexts, and precision/quantization. Include visualization-first content like Mermaid diagrams, tables, and code snippets. Write the raw markdown output directly to E:\De Anima\_tmp\kv_cache_chunk_02.md",
    "You are Ibn Haytham (Science domain agent). Write a 1000-word section on 'Memory Bandwidth vs Compute Bound Operations'. Explain the decoding phase vs prefill phase in LLMs. How the decoding phase is heavily memory bandwidth bound and how GPUs manage HBM (High Bandwidth Memory). Include diagrams and math tables. Write the raw markdown output directly to E:\De Anima\_tmp\kv_cache_chunk_03.md",
    "You are Ibn Haytham (Science domain agent). Write a 1000-word section on 'Scaling Challenges: Multi-GPU and PagedAttention'. Address how large context windows exhaust single GPU memory. Discuss solutions like PagedAttention, vLLM, RingAttention, and Tensor Parallelism across NVLink/NVSwitch. Use diagrams. Write the raw markdown output directly to E:\De Anima\_tmp\kv_cache_chunk_04.md",
    "You are Ibn Haytham (Science domain agent). Write a 1000-word section on 'Future Architectures and Optimization Techniques'. Explore upcoming hardware trends, LPUs, NPUs, MoE impact on caches, sparse attention, and context compression. Write the raw markdown output directly to E:\De Anima\_tmp\kv_cache_chunk_05.md"
)

for ($i = 0; $i -lt $prompts.Length; $i++) {
    $num = "{0:D2}" -f ($i + 1)
    $file = "E:\De Anima\_tmp\${slug}_chunk_${num}.md"
    $prompt = $prompts[$i]
    
    Write-Host "Executing YOLO for chunk $num..."
    gemini -y -p "$prompt"
    
    if (Test-Path $file) {
        Write-Host "Success chunk $num. Waiting 15s..."
        Start-Sleep -Seconds 15
    } else {
        Write-Host "Failed chunk $num. Waiting 30s and retrying..."
        Start-Sleep -Seconds 30
        gemini -y -p "$prompt"
        if (Test-Path $file) {
            Write-Host "Success chunk $num on retry. Waiting 15s..."
            Start-Sleep -Seconds 15
        } else {
            Write-Host "Failed chunk $num after retry."
        }
    }
}
Write-Host "YOLO COMPLETE`nTopic: KV Caches and AI Hardware Architecture`nSlug: $slug`nExpected chunks: 5`nChunk path pattern: E:\De Anima\_tmp\${slug}_chunk_[NN].md`nHandoff: weaver"