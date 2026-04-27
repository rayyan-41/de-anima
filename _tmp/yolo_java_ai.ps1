$slug = "java-and-artificial-intelligence"
$tmpDir = "E:\De Anima\_tmp"
$prompts = @(
    "Write an exhaustive ~1000-word technical section for 'Java and Artificial Intelligence' on 'Introduction: The Enterprise Giant in the AI Era'. Use empirical data, contrast Python's R&D dominance with Java's enterprise orchestration, and include a comparison table. Output raw markdown directly to $tmpDir\${slug}_chunk_01.md",
    "Write an exhaustive ~1000-word technical section for 'Java and Artificial Intelligence' on 'Historical Context: Java''s Early AI Ecosystem'. Explore Weka, Deeplearning4j, Apache OpenNLP, and MOA. Discuss why Python won research and Java won data pipelines (Hadoop, Spark). Output raw markdown directly to $tmpDir\${slug}_chunk_02.md",
    "Write an exhaustive ~1000-word technical section for 'Java and Artificial Intelligence' on 'The Deployment Gap: Why Enterprise AI Needs Java'. Discuss type safety, multi-threading, security, observability, and legacy integration vs Jupyter Notebooks. Output raw markdown directly to $tmpDir\${slug}_chunk_03.md",
    "Write an exhaustive ~1000-word technical section for 'Java and Artificial Intelligence' on 'The Modern Renaissance: LangChain4j and LLM Orchestration'. Deep dive into LangChain4j. Include a Mermaid diagram of Java LLM orchestration and a foundational LangChain4j Java code snippet. Output raw markdown directly to $tmpDir\${slug}_chunk_04.md",
    "Write an exhaustive ~1000-word technical section for 'Java and Artificial Intelligence' on 'Architectural Shifts: Project Loom, Panama, and High-Concurrency AI'. Focus on Virtual Threads solving I/O bottlenecks for LLM calls, and Project Panama bridging native GPU/tensor ops. Include code snippets or diagrams if helpful. Output raw markdown directly to $tmpDir\${slug}_chunk_05.md",
    "Write an exhaustive ~1000-word technical section for 'Java and Artificial Intelligence' on 'RAG and Vector Data Management on the JVM'. Cover implementing RAG, JVM drivers for vector DBs (Milvus, Pinecone, pgvector), document parsing, and embedding generation in enterprise Java. Include code snippets. Output raw markdown directly to $tmpDir\${slug}_chunk_06.md",
    "Write an exhaustive ~1000-word technical section for 'Java and Artificial Intelligence' on 'Conclusion: The Bifurcated Future of AI'. Synthesize the trajectory: Python for training/research, Java for inference/agentic orchestration/enterprise deployment. Output raw markdown directly to $tmpDir\${slug}_chunk_07.md"
)

$failed_chunks = @()

for ($i = 0; $i -lt $prompts.Count; $i++) {
    $num = ($i + 1).ToString("00")
    $outFile = "$tmpDir\${slug}_chunk_${num}.md"
    
    if (Test-Path $outFile) {
        Write-Host "Chunk $num already exists. Skipping."
        continue
    }

    $prompt = "You are Ibn Haytham, Science domain agent. " + $prompts[$i]
    Write-Host "Executing YOLO for Chunk $num..."
    
    gemini -y -p "$prompt"
    
    Write-Host "Waiting 15 seconds..."
    Start-Sleep -Seconds 15
    
    if (-not (Test-Path $outFile)) {
        Write-Host "Chunk $num missing! Retrying in 30 seconds..."
        Start-Sleep -Seconds 30
        gemini -y -p "$prompt"
        Write-Host "Waiting 15 seconds after retry..."
        Start-Sleep -Seconds 15
    }
    
    if (-not (Test-Path $outFile)) {
        Write-Host "Chunk $num failed permanently."
        $failed_chunks += $num
    }
}

$writtenCount = $prompts.Count - $failed_chunks.Count

Write-Host ""
Write-Host "YOLO COMPLETE"
Write-Host "Topic: Java and Artificial Intelligence"
Write-Host "Slug: $slug"
Write-Host "Expected chunks: $($prompts.Count)"
Write-Host "Written chunks: $writtenCount"
if ($failed_chunks.Count -gt 0) {
    Write-Host "Failed chunks: $($failed_chunks -join ', ')"
} else {
    Write-Host "Failed chunks: none"
}
Write-Host "Chunk path pattern: E:\De Anima\_tmp\${slug}_chunk_[NN].md"
Write-Host "Handoff: weaver"