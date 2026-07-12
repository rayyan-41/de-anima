powershell -File C:\Users\Pc\.gemini\tools\write_manifest.ps1 -Slug "triangles-basis-rasterization" -Headings "Introduction: Digital Geometry and the Primacy of the Triangle","Theoretical Geometry: Inherent Properties (Planarity, Convexity, and Interpolation)","Barycentric Coordinates: The Mathematics of Spatial Weighting","Algorithmic Rasterization: Edge Equations and Scanline Techniques","The Modern Graphics Pipeline: Triangles at Scale"
powershell -File C:\Users\Pc\.gemini\tools\update_pipeline_state.ps1 -Slug "triangles-basis-rasterization" -Stage preflight -Status complete

$prompts = @(
    "You are Ibn Haytham, the Science domain agent for the De Anima vault. Your method is Visualization-first — Mermaid diagrams, tables, code snippets, then prose. Write a 1000-word section on 'Introduction: Digital Geometry and the Primacy of the Triangle' for the note 'Triangles as the basis for Rasterization'. Focus on deep theory and visualization. Write the output as raw markdown text directly to E:\De Anima\_tmp\triangles-basis-rasterization_chunk_01.md",
    "You are Ibn Haytham, the Science domain agent for the De Anima vault. Your method is Visualization-first. Write a 1000-word section on 'Theoretical Geometry: Inherent Properties (Planarity, Convexity, and Interpolation)'. Focus on theoretical geometrical knowledge on triangles themselves, deep theory, math, and visualization. Write the output as raw markdown text directly to E:\De Anima\_tmp\triangles-basis-rasterization_chunk_02.md",
    "You are Ibn Haytham, the Science domain agent for the De Anima vault. Your method is Visualization-first. Write a 1000-word section on 'Barycentric Coordinates: The Mathematics of Spatial Weighting'. Focus on deep theory, algorithms, math blocks, and visualization. Write the output as raw markdown text directly to E:\De Anima\_tmp\triangles-basis-rasterization_chunk_03.md",
    "You are Ibn Haytham, the Science domain agent for the De Anima vault. Your method is Visualization-first. Write a 1000-word section on 'Algorithmic Rasterization: Edge Equations and Scanline Techniques'. Focus on deep theory, code snippets, and visualization. Write the output as raw markdown text directly to E:\De Anima\_tmp\triangles-basis-rasterization_chunk_04.md",
    "You are Ibn Haytham, the Science domain agent for the De Anima vault. Your method is Visualization-first. Write a 1000-word section on 'The Modern Graphics Pipeline: Triangles at Scale'. Focus on modern GPU architecture, deep theory, and visualization. Write the output as raw markdown text directly to E:\De Anima\_tmp\triangles-basis-rasterization_chunk_05.md"
)

foreach ($prompt in $prompts) {
    Write-Host "Running: agy --dangerously-skip-permissions -p `"$prompt`""
    agy --dangerously-skip-permissions -p "$prompt"
    Write-Host "Waiting 15 seconds..."
    Start-Sleep -Seconds 15
}

powershell -File C:\Users\Pc\.gemini\tools\update_pipeline_state.ps1 -Slug "triangles-basis-rasterization" -Stage yolo -Status complete
Write-Host "YOLO Execution Complete."
