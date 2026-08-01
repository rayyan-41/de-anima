---
name: yolo_generation_protocol
description: Authoritative execution protocol for full-note drafting in the De Anima vault. Governs section-by-section generation - one sub-generation per heading, chunk file naming, retry handling, and handoff to the weaver agent.
---

# YOLO Generation Protocol

## Purpose

This skill is the authoritative execution protocol for full-note drafting in the De Anima vault.
It standardizes how content agents generate section chunks, handle retries, and hand off to assembly.

If any agent-local instruction conflicts with this skill, this skill wins.

## Use When

- The user requests a full drafted note.
- A content agent must write long-form output across multiple headings.
- The workflow must produce chunk files in `_tmp\` for weaver.

## Do Not Use When

- The user asks for a short answer, quick outline, or editing advice only.
- The task is pure tagging, linking, MOC updates, or vault auditing.

## Required Inputs

- `topic`: full note topic
- `domain`: art, history, islam, literature, reason, or science
- `template`: domain template family (for example empire, biography, fiqh, cs)
- `headings`: ordered list of section headings
- `topic_slug`: lowercase hyphenated slug
- `expected_count`: number of headings/chunks

## The SPAWN_SECTION Primitive

Section generation is delegated to the harness, which must provide one primitive:

```
SPAWN_SECTION slug=[topic_slug] index=[NN] <<
[the section prompt]
>>
```

Contract:

- The harness runs the prompt in a **fresh generation context** — no history from
  previous sections. This is the whole point: it keeps section N+1 from degrading
  under the accumulated weight of sections 1..N.
- The harness writes the result to `_tmp\[topic_slug]_chunk_[NN].md` and nothing else.
- The harness returns success or failure. It does not interpret the content.
- The calling agent never writes chunk files directly.

The protocol is model- and provider-agnostic. Any backend that satisfies this
contract is valid. Do not assume a particular CLI, API, or vendor.

## Non-Negotiable Invariants

- One `SPAWN_SECTION` call per heading.
- One chunk file per heading.
- No merged headings in one chunk.
- Retry once after failure.
- Continue even if one heading fails after retry; report failures explicitly.

## Execution Steps

### 1) Pre-Flight Gate

Before generation starts, output a pre-flight checklist:

- Topic
- Domain
- Template
- Ordered headings
- Estimated sections
- Target word count (`N * 1000`)
- Target chunk path pattern
- Confirmation sentence: `Executing [N] section generations.`

Then record the plan:

```powershell
powershell -File ".agents\tools\write_manifest.ps1" -Slug "[topic_slug]" -Headings "[H1],[H2],...,[HN]"
```

Must return `MANIFEST_WRITTEN`. If it does not, stop and report — do not generate
sections without a manifest, because weaver uses it to verify completeness.

Generation must not start before this gate is complete.

### 2) Build Heading Plan

Create a heading list from the agent's domain-specific template.

Rules:
- Headings must be specific and non-overlapping.
- Each heading should support roughly 700-1200 words.
- Preserve chronological order where the domain requires it.

### 3) Generate Each Section

For each heading index `NN`, issue one `SPAWN_SECTION` call scoped to that heading only.

Prompt requirements for each section:
- Approximate target: 1000 words.
- Domain-appropriate tone and evidence standard.
- Section-only output — no preamble, no meta commentary, no restated heading.

### 4) Verify and Retry

After each `SPAWN_SECTION` call:

1. Verify the chunk file exists.
2. If missing: retry once.
3. If still missing: mark the heading as failed and continue to the next.

No pacing delay is required. If a backend imposes rate limits, that is the
harness's concern, not this protocol's.

### 5) Completion Contract

When all headings are attempted, output:

```text
YOLO COMPLETE
Topic: [topic]
Slug: [topic_slug]
Expected chunks: [N]
Written chunks: [M]
Failed chunks: [list or none]
Chunk path pattern: _tmp\[topic_slug]_chunk_[NN].md
Handoff: weaver
```

## Quality Rules

- No section should rely on another section to make sense.
- Avoid repeated paragraphs across chunks.
- Keep factual claims scoped to the heading context.
- Preserve tables, code blocks, and diagram syntax generated in chunks.
- Do not emit a Table of Contents inside a chunk — weaver generates it.

## Safety and Reliability

- Never write chunk files outside `_tmp\`.
- Never overwrite sacred files (see AGENTS.md).
- Do not hang the run on a single-section failure.
- Report incomplete chunk sets explicitly for weaver.

## Quick Checklist

- Pre-flight gate printed
- `write_manifest.ps1` returned `MANIFEST_WRITTEN`
- Heading plan finalized
- One `SPAWN_SECTION` call per heading
- Retry-once on failure
- Completion report emitted
- Handoff to weaver
