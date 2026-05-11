$prompts = @(
    "You are Avicenna, the systematic philosophical Reason agent. Write a 1000-word philosophical section on 'The Classical Dawn - Plato Aristotle and the Birth of Logic' exploring how early rationality externalized truth into Forms and syllogisms. Focus purely on the content section. Write the output as raw markdown text directly to `"E:\De Anima\_tmp\historical-ascent-reason_chunk_01.md`"",
    "You are Avicenna, the systematic philosophical Reason agent. Write a 1000-word philosophical section on 'The Scholastic Synthesis - Preserving and Elevating Antiquity' explaining how the Islamic Golden Age and Medieval Europe synthesized philosophy and theology, demonstrating Hegelian preservation. Focus purely on the content section. Write the output as raw markdown text directly to `"E:\De Anima\_tmp\historical-ascent-reason_chunk_02.md`"",
    "You are Avicenna, the systematic philosophical Reason agent. Write a 1000-word philosophical section on 'The Rationalist Fracture - Descartes Spinoza and the Subjective Turn' discussing the Enlightenment's shift to the internal mind and the fracture between subject and object. Focus purely on the content section. Write the output as raw markdown text directly to `"E:\De Anima\_tmp\historical-ascent-reason_chunk_03.md`"",
    "You are Avicenna, the systematic philosophical Reason agent. Write a 1000-word philosophical section on 'The Transcendental Limit - Kant and the Crisis of Pure Reason' detailing how Kant mapped the limits of rationality (Phenomena vs Noumena) creating philosophical tension. Focus purely on the content section. Write the output as raw markdown text directly to `"E:\De Anima\_tmp\historical-ascent-reason_chunk_04.md`"",
    "You are Avicenna, the systematic philosophical Reason agent. Write a 1000-word philosophical section on 'The Hegelian Culmination - Dissecting the Absolute Idea' explaining how Hegel resolves the Kantian crisis through Aufhebung, showing history as Reason working out its contradictions. Focus purely on the content section. Write the output as raw markdown text directly to `"E:\De Anima\_tmp\historical-ascent-reason_chunk_05.md`"",
    "You are Avicenna, the systematic philosophical Reason agent. Write a 1000-word philosophical section on 'The Absolute in Action - Paradigm Shifts and Modern Rationality' applying the Absolute Idea to modernity, showing how scientific and societal evolution is Reason coming to know itself. Focus purely on the content section. Write the output as raw markdown text directly to `"E:\De Anima\_tmp\historical-ascent-reason_chunk_06.md`""
)

foreach ($prompt in $prompts) {
    Write-Host "Running chunk generation..."
    Out-File -FilePath "E:\De Anima\_tmp\current_prompt.txt" -InputObject $prompt -Encoding utf8
    Get-Content "E:\De Anima\_tmp\current_prompt.txt" | gemini -y -p " "
    Write-Host "Waiting 15 seconds..."
    Start-Sleep -Seconds 15
}
Write-Host "YOLO Execution Complete."
