$ErrorActionPreference = 'Stop'
Set-Location -Path "E:\De Anima"

$levant_prompts = @(
    "@machiavelli Write a 1000-word historical section on 'The Fatimid Era: Shi''ite Rule and Byzantine Intrusions (969-1071 CE)' in the Levant. Write the output as raw markdown text directly to E:\De Anima\_tmp\levant_chunk_05.md",
    "@machiavelli Write a 1000-word historical section on 'The Seljuks and the Crusader Interlude (1071-1187 CE)' in the Levant. Write the output as raw markdown text directly to E:\De Anima\_tmp\levant_chunk_06.md",
    "@machiavelli Write a 1000-word historical section on 'The Ayyubid Renaissance: Saladin and the Re-unification (1174-1260 CE)' in the Levant. Write the output as raw markdown text directly to E:\De Anima\_tmp\levant_chunk_07.md",
    "@machiavelli Write a 1000-word historical section on 'The Mamluk Sultanate: Defenders of the Levant and Architectural Flourishing (1260-1516 CE)' in the Levant. Write the output as raw markdown text directly to E:\De Anima\_tmp\levant_chunk_08.md",
    "@machiavelli Write a 1000-word historical section on 'Conclusion: The Enduring Islamic Legacy in the Levant' summarizing the rule from Rashidun to Mamluks. Write the output as raw markdown text directly to E:\De Anima\_tmp\levant_chunk_09.md"
)

foreach ($prompt in $levant_prompts) {
    Write-Host "Running chunk generation..."
    gemini -y -p "$prompt"
    Start-Sleep -Seconds 15
}
Write-Host "Levant chunk generation complete."
