$hannibal_prompts = @(
    "Write a 1000-word historical section on 'Introduction: The Spectre of Cannae' focusing on Hannibal's legacy and how he was etched into Roman history. Write the output as raw markdown text directly to E:\De Anima\_tmp\hannibal_chunk_01.md",
    "Write a 1000-word historical section on 'Hannibal ad Portas: The Psychological Trauma and the Roman Bogeyman' focusing on the psychological effect of Hannibal's invasion on Roman society. Write the output as raw markdown text directly to E:\De Anima\_tmp\hannibal_chunk_02.md",
    "Write a 1000-word historical section on 'Metamorphosis of the Legions: The Scipionic Paradigm' focusing on how Hannibal forced Roman military evolution. Write the output as raw markdown text directly to E:\De Anima\_tmp\hannibal_chunk_03.md",
    "Write a 1000-word historical section on 'Cultural Echoes: Gladiators, Rhetoric, and Literature' focusing on how Hannibal was mentioned in gladiator battles, rhetoric, and literature in Rome. Write the output as raw markdown text directly to E:\De Anima\_tmp\hannibal_chunk_04.md",
    "Write a 1000-word historical section on 'Conclusion: The Immortal Enemy' summarizing how Hannibal's actions forever changed Roman society. Write the output as raw markdown text directly to E:\De Anima\_tmp\hannibal_chunk_05.md"
)

foreach ($prompt in $hannibal_prompts) {
    Write-Host "Running: gemini -y -p '$prompt'"
    gemini -y -p "$prompt"
    Write-Host "Waiting 15 seconds..."
    Start-Sleep -Seconds 15
}

$levant_prompts = @(
    "Write a 1000-word historical section on 'Introduction: The Levant as the Crossroads of Empires' focusing on Muslim rule. Write the output as raw markdown text directly to E:\De Anima\_tmp\levant_chunk_01.md",
    "Write a 1000-word historical section on 'The Rashidun Conquest: Integration and the Pact of Umar (634-661 CE)' in the Levant. Write the output as raw markdown text directly to E:\De Anima\_tmp\levant_chunk_02.md",
    "Write a 1000-word historical section on 'The Umayyad Caliphate: The Syrian Heartland and Monumental Architecture (661-750 CE)' in the Levant. Write the output as raw markdown text directly to E:\De Anima\_tmp\levant_chunk_03.md",
    "Write a 1000-word historical section on 'The Abbasid Shift: Marginalization and Provincial Dynamics (750-969 CE)' in the Levant. Write the output as raw markdown text directly to E:\De Anima\_tmp\levant_chunk_04.md",
    "Write a 1000-word historical section on 'The Fatimid Era: Shi''ite Rule and Byzantine Intrusions (969-1071 CE)' in the Levant. Write the output as raw markdown text directly to E:\De Anima\_tmp\levant_chunk_05.md",
    "Write a 1000-word historical section on 'The Seljuks and the Crusader Interlude (1071-1187 CE)' in the Levant. Write the output as raw markdown text directly to E:\De Anima\_tmp\levant_chunk_06.md",
    "Write a 1000-word historical section on 'The Ayyubid Renaissance: Saladin and the Re-unification (1174-1260 CE)' in the Levant. Write the output as raw markdown text directly to E:\De Anima\_tmp\levant_chunk_07.md",
    "Write a 1000-word historical section on 'The Mamluk Sultanate: Defenders of the Levant and Architectural Flourishing (1260-1516 CE)' in the Levant. Write the output as raw markdown text directly to E:\De Anima\_tmp\levant_chunk_08.md",
    "Write a 1000-word historical section on 'Conclusion: The Enduring Islamic Legacy in the Levant' summarizing the rule from Rashidun to Mamluks. Write the output as raw markdown text directly to E:\De Anima\_tmp\levant_chunk_09.md"
)

foreach ($prompt in $levant_prompts) {
    Write-Host "Running: gemini -y -p '$prompt'"
    gemini -y -p "$prompt"
    Write-Host "Waiting 15 seconds..."
    Start-Sleep -Seconds 15
}

Write-Host "YOLO Execution Complete."