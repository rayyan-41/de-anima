---
name: obsidian_wikilink_engine
description: "The deterministic protocol for how vault notes are inter-linked and mapped."
---

# Obsidian Wikilink Engine

## Purpose
This skill encapsulates the rules for finding relations and inserting wikilinks. It is used primarily by `@linker` and `@technician` during the standardization pipelines to prevent hallucinations and enforce cross-referencing.

## Execution Rules

### Step 1: Identify Link Candidates (Method A: Named Entity Matching)

Scan the note body for **named entities** — people, places, concepts, movements, texts, historical events — that appear as titles of existing vault notes.

**Matching rules**:
- Match note titles to text appearing in the note body.
- Strip prefixes when matching (e.g., `BIO - Ibn Sina` → match `Ibn Sina` in text).
- Case-insensitive matching.
- **CRITICAL**: Only match entities that have an existing vault note — do NOT fabricate or hallucinate links to notes that don't exist. Check the vault index (via filesystem recursively) first.

**Cross-domain linking is encouraged:**
- A Fiqh note mentioning **Ibn Taymiyyah** → link to `History/Biographies/BIO - Ibn Taymiyyah.md` if it exists
- A Science note mentioning the **Ottoman Empire** → link to the relevant EMP note if it exists

### Step 2: Identify Related Notes (Method B: Tag Overlap)

Read the `tags:` array from the current note's YAML frontmatter. Then scan the vault index and read the `tags:` field of every other note.

**Tag overlap rule**: Any note sharing **2 or more topic tags** with the current note is a Related Note candidate.
- Count shared tags between the current note and each candidate (excluding the domain tag and `ai-generated`).
- Rank candidates by number of shared tags (highest first).
- Take the top 3–5 candidates that are not already captured by Method A.
- These go into **Related Notes only** — do NOT insert them as inline `[[wikilinks]]` in the body.

### Step 3: Apply the First-Mention Rule

Insert `[[wikilinks]]` discovered via Method A according to the **first-mention rule**:
- Link each entity **ONCE only** — on its first appearance in the body.
- Do NOT link inside headings, code blocks, Mermaid diagrams, or Quranic/Hadith references.
- Minimum 2 wikilinks (flag warning if vault is too sparse).
- Maximum 8 wikilinks (prevents text clutter).
- Use aliases for readability: `[[BIO - Ibn Taymiyyah|Ibn Taymiyyah]]`

### Step 4: Populate `## Related Notes`

Write the `## Related Notes` section at the end of the note, drawing from **both** discovery methods:

```markdown
## Related Notes

- [[BIO - Ibn Taymiyyah|Ibn Taymiyyah]] — scholar whose legal methodology is directly relevant
- [[FIQH - Ruku in Prayer|Ruku in Prayer]] — related Fiqh ruling (2 shared tags: prayer, ibadat)
- [[_Islam - Map of Contents|Islam MOC]]
```

**Rules**:
- Include 2–5 related notes total.
- Prioritize notes found by both methods (entity match + tag overlap).
- Add a brief (5–10 word) annotation explaining the relevance.
- For tag-overlap-only entries, note the shared tags in the annotation.
- Do not add the domain MOC unless there are fewer than 2 other candidates.

### Step 5: Update the Domain MOC

After modifying the file, you must update the domain's root `Map of Contents` (MOC) file using the specific PowerShell tool:

```powershell
powershell -File "C:\Users\Pc\.gemini\tools\update_moc.ps1" -Domain "[domain]" -NoteTitle "[title]" -NoteFilename "[filename]" -Category "[category]"
```
