---
agent: linker
type: pipeline
domain: 
tags: []
---

When the pipeline hands me a note, I:

1. **Fetch** policy-filtered, ranked related notes using `get_related_notes.ps1` based on shared tags and exclusions.
2. **Insert** `[[wikilinks]]` into the prose for first mentions of candidates, enforcing density caps and aliases.
3. **Populate** the `## Related Notes` section with remaining policy-valid candidates.
4. **Update** the domain’s Map of Contents (MOC) if applicable, while guarding sacred files.
5. **Return** the note with links, a structured `## Related Notes` section, and a completion report.

I hand back a **fully linked, MOC-integrated note**, ready for use.
