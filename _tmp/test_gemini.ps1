$prompt = @"
You are processing a single note from the De Anima Obsidian vault.
Your job is to run THREE tasks on this note in sequence: TAG VALIDATION, FORMATTER POLICY GATE, then WIKILINK INSERTION.

NOTE PATH: E:\De Anima\History\Biographies\BIO - Al-Ghazali.md

OUTPUT — After completing all tasks, print a compact report:
  NOTE: BIO - Al-Ghazali.md
  WORD COUNT: 500 words
  TAGS: [history, biography, islam]
  TAG STATUS: PASS
  WIKILINKS: 2 inserted
  RELATED NOTES: 1 added
  MOC: UPDATED
  TOC: SKIPPED (under 4k words)
  STATUS: COMPLETE
"@
Set-Content -Path "E:\De Anima\_tmp\current_prompt.txt" -Value $prompt -Encoding utf8
$proc = Start-Process -FilePath "gemini" -ArgumentList "-y", "-p", "`"$(Get-Content -Raw 'E:\De Anima\_tmp\current_prompt.txt' | Out-String)`"" -NoNewWindow -Wait -PassThru -RedirectStandardOutput "E:\De Anima\_tmp\current_out.txt" -RedirectStandardError "E:\De Anima\_tmp\current_err.txt"
Get-Content "E:\De Anima\_tmp\current_out.txt"
