$ErrorActionPreference = 'Stop'
Set-Location -Path "E:\De Anima"

Write-Host "Running chunk 1..."
gemini -y -p "@machiavelli You are generating section 1 for 'Hannibal''s Legacy - How he was etched in Roman History'. Heading: '1. Introduction: The Spectre of Cannae'. Write ~1000 words of factual, documentary history. Output the complete text of this section, formatted in Markdown, into the file 'E:\De Anima\_tmp\hannibal_legacy_chunk_01.md'"
Start-Sleep -Seconds 15

Write-Host "Running chunk 2..."
gemini -y -p "@machiavelli You are generating section 2 for 'Hannibal''s Legacy - How he was etched in Roman History'. Heading: '2. Hannibal ad Portas: The Psychological Trauma and the Roman Bogeyman'. Write ~1000 words of factual, documentary history. Output the complete text of this section, formatted in Markdown, into the file 'E:\De Anima\_tmp\hannibal_legacy_chunk_02.md'"
Start-Sleep -Seconds 15

Write-Host "Running chunk 3..."
gemini -y -p "@machiavelli You are generating section 3 for 'Hannibal''s Legacy - How he was etched in Roman History'. Heading: '3. Metamorphosis of the Legions: The Scipionic Paradigm'. Write ~1000 words of factual, documentary history. Output the complete text of this section, formatted in Markdown, into the file 'E:\De Anima\_tmp\hannibal_legacy_chunk_03.md'"
Start-Sleep -Seconds 15

Write-Host "Running chunk 4..."
gemini -y -p "@machiavelli You are generating section 4 for 'Hannibal''s Legacy - How he was etched in Roman History'. Heading: '4. Cultural Echoes: Gladiators, Rhetoric, and Literature'. Write ~1000 words of factual, documentary history. Output the complete text of this section, formatted in Markdown, into the file 'E:\De Anima\_tmp\hannibal_legacy_chunk_04.md'"
Start-Sleep -Seconds 15

Write-Host "Running chunk 5..."
gemini -y -p "@machiavelli You are generating section 5 for 'Hannibal''s Legacy - How he was etched in Roman History'. Heading: '5. Conclusion: The Immortal Enemy'. Write ~1000 words of factual, documentary history. Output the complete text of this section, formatted in Markdown, into the file 'E:\De Anima\_tmp\hannibal_legacy_chunk_05.md'"
Write-Host "All chunks generated."