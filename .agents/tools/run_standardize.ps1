param(
    [string]$domain = "History",

    # Command the harness uses to run one prompt in a fresh agent context.
    # It receives the prompt file path as its only argument and writes the
    # agent's output to stdout. Provider-neutral by design.
    [string]$AgentCommand = $env:DEANIMA_AGENT_CMD
)

if (-not $AgentCommand) {
    Write-Error ("STANDARDIZE_ERROR: no agent command configured. " +
        "Set the DEANIMA_AGENT_CMD environment variable (or pass -AgentCommand) to the " +
        "command your harness uses to run a single prompt in a fresh context. " +
        "It is invoked as: <AgentCommand> <path to prompt file>")
    exit 1
}
$VaultRoot = (Resolve-Path "$PSScriptRoot\..\..").Path
$notes = @(Get-ChildItem -Path "$VaultRoot\$domain" -Recurse -Filter "*.md" | Where-Object { $_.Name -notmatch "^_.*Map of Content" })

Write-Host "STANDARDIZE: $domain"
Write-Host "Notes found: $($notes.Count)"
Write-Host "-----------------------------"
$i = 1
foreach ($note in $notes) {
    Write-Host (" {0}. {1} - {2}" -f $i, $note.Name, $note.FullName)
    $i++
}
Write-Host "-----------------------------"
Write-Host "Spawning $($notes.Count) sub-sessions."

$successCount = 0
$failCount = 0
$failedNotes = @()
$results = @()

foreach ($note in $notes) {
    $prompt = @"
You are processing a single note from the De Anima Obsidian vault.
Your job is to run THREE tasks on this note in sequence: TAG VALIDATION, FORMATTER POLICY GATE, then WIKILINK INSERTION.

NOTE PATH: $($note.FullName)

========================================
TASK A - TAG VALIDATION (@tagger logic)
========================================

Read the note at the path above.

Locate the YAML frontmatter block (between --- markers at the top of the file).
Find the tags: field. It may be [PLACEHOLDER], missing, or already populated.

Load the obsidian_yaml_enforcer skill from $($VaultRoot)\.agents\skills\obsidian_yaml_enforcer\SKILL.md.
Follow its strict rules to build the correct tag array based on the note's actual content.

Rewrite ONLY the tags: line in the frontmatter with the correct array.
Also ensure title:, date:, domain:, category:, status: fields exist and are valid according to the skill.
Do not touch any content outside the frontmatter block.

Run validation:
  powershell -File "$($PSScriptRoot)\validate_tags.ps1" -TagLine "[your constructed tags comma-separated without #]"

If PASS - write the corrected frontmatter to the file.
If FAIL - correct the specific issues flagged and re-run until PASS.

========================================
TASK B - FORMATTER POLICY GATE (@formatter logic)
========================================

After tags are validated and written, run a formatter-style second pass:
- Re-run tag validation and fix if needed.
- Build core tag set and supporting tag set.
- Build excluded_mentions list for incidental entities.
- Define backlink rules:
  1) >=2 shared core tags, OR
  2) >=1 shared core tag AND same category.

Only then proceed to link insertion.

========================================
TASK C - WIKILINK INSERTION (@linker logic)
========================================

Build a vault index by listing all .md files under $($VaultRoot)\ recursively,
excluding: _tmp/, .obsidian/, paintings_source/, MOC files, sacred files.

Scan the note body for named entities (people, places, concepts, movements, texts,
historical events) that match existing vault note titles.

Load the obsidian_wikilink_engine skill from $($VaultRoot)\.agents\skills\obsidian_wikilink_engine\SKILL.md.
Follow its exact multi-step execution rules to find entities, but only insert links that satisfy Task B policy rules.

Update the domain MOC:
  powershell -File "$($PSScriptRoot)\update_moc.ps1" -Domain "$domain" -NoteTitle "[title]" -NoteFilename "$($note.Name)" -Category "[category]"
================================================
TASK D - TABLE OF CONTENTS (mandatory for all cli notes)
================================================

After completing Task C, count the words in the note body (excluding frontmatter).

For every cli note, regardless of length:
- Extract every ## heading (H2 level) from the note body, in order
- Generate a Table of Contents in this format:

  ## Table of Contents
  - [Section Name](#section-name)
  - [Section Name](#section-name)
  ...

  Anchor links: lowercase the heading, replace spaces with hyphens, strip special characters.
  Example: ## The Four Madhabs -> (#the-four-madhabs)

- Insert the Table of Contents block IMMEDIATELY after the closing --- of the frontmatter,
  before the note title or first heading.

- If a Table of Contents section already exists in the note, REPLACE it with the freshly
  generated one (headings may have changed).

Skip only if the note has fewer than two content headings - a ToC would have nothing to list.

OUTPUT - After completing all tasks, print a compact report:
  NOTE: $($note.Name)
  WORD COUNT: [N] words
  TAGS: [final tags array]
  TAG STATUS: [PASS / CORRECTED]
  WIKILINKS: [N inserted] - [list them briefly]
  RELATED NOTES: [N added]
  MOC: [UPDATED / ALREADY_LISTED / CREATED]
  TOC: [INSERTED / UPDATED / SKIPPED (fewer than 2 headings)]
  STATUS: COMPLETE
"@
    Set-Content -Path "$VaultRoot\_tmp\current_prompt.txt" -Value $prompt -Encoding utf8
    
    & cmd.exe /c "$AgentCommand `"$VaultRoot\_tmp\current_prompt.txt`" > `"$VaultRoot\_tmp\current_out.txt`" 2> `"$VaultRoot\_tmp\current_err.txt`""
    $exitCode = $LASTEXITCODE


    $outContent = Get-Content "$VaultRoot\_tmp\current_out.txt" -Raw
    if ($exitCode -eq 0 -and $outContent -match "STATUS: COMPLETE") {
        Write-Host "✅ $($note.Name) - Successfully processed"
        $results += "  ✅ $($note.Name) - tags corrected, wikilinks inserted, MOC updated"
        $successCount++
    } else {
        & cmd.exe /c "$AgentCommand `"$VaultRoot\_tmp\current_prompt.txt`" > `"$VaultRoot\_tmp\current_out.txt`" 2> `"$VaultRoot\_tmp\current_err.txt`""
        $exitCode2 = $LASTEXITCODE
            $outContent2 = Get-Content "$VaultRoot\_tmp\current_out.txt" -Raw

        if ($exitCode2 -eq 0 -and $outContent2 -match "STATUS: COMPLETE") {
            Write-Host "✅ $($note.Name) - Successfully processed on retry"
            $results += "  ✅ $($note.Name) - tags corrected, wikilinks inserted, MOC updated (retried)"
            $successCount++
        } else {
            Write-Host "❌ $($note.Name) - FAILED (retry exhausted)"
            $results += "  ❌ $($note.Name) - FAILED (retry exhausted)"
            $failCount++
            $failedNotes += "- $($note.Name): Sub-session failed or didn't output STATUS: COMPLETE"
        }
    }
}

Write-Host "============================================"
Write-Host "STANDARDIZE COMPLETE - $domain"
Write-Host "============================================"
Write-Host "Total notes processed : $($notes.Count)"
Write-Host "Successful            : $successCount"
Write-Host "Failed / Skipped      : $failCount"
Write-Host "--------------------------------------------"
Write-Host "PER-NOTE RESULTS:"
foreach ($res in $results) { Write-Host $res }
Write-Host "--------------------------------------------"
if ($failedNotes.Count -gt 0) {
    Write-Host "FAILED NOTES (require manual attention):"
    foreach ($fn in $failedNotes) { Write-Host $fn }
}
Write-Host "============================================"
