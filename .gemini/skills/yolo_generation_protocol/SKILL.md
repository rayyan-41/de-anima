---
name: yolo_generation_protocol
description: "Canonical section-by-section YOLO generation workflow for De Anima content agents. Use for full note drafting that must run per-heading chunk generation, enforce rate-limit pacing, and hand off assembled chunks to weaver."
---

# YOLO Generation Protocol

## Purpose

This skill is the authoritative execution protocol for full-note drafting in the De Anima vault.
It standardizes how content agents generate section chunks, handle retries, and hand off to assembly.

If any agent-local instruction conflicts with this skill, this skill wins.

## Use When

- The user requests a full drafted note.
- A content agent must write long-form output across multiple headings.
- The workflow must produce chunk files in `E:\De Anima\_tmp\` for weaver.

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

## Non-Negotiable Invariants

- One YOLO call per heading.
- One chunk file per heading.
- No merged headings in one chunk.
- Mandatory 15-second wait between successful YOLO calls.
- Retry once after failure, with a 30-second wait.
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
- Confirmation sentence: `Executing [N] YOLO sessions.`

Generation must not start before this gate is complete.

### 2) Build Heading Plan

Create a heading list from the agent's domain-specific template.

Rules:
- Headings must be specific and non-overlapping.
- Each heading should support roughly 700-1200 words.
- Preserve chronological order where the domain requires it.

### 3) Spawn Per-Heading YOLO Calls

For each heading index `NN`:

- Execute a dedicated `gemini -y -p` prompt scoped to that heading only.
- Require output to be written to:
  `E:\De Anima\_tmp\[topic_slug]_chunk_[NN].md`

Prompt requirements for each heading:
- Approximate target: 1000 words.
- Domain-appropriate tone and evidence standard.
- Section-only output (no preamble, no meta commentary).

### 4) Verify + Pace + Retry

After each YOLO call:

1. Verify the chunk file exists.
2. If present: wait 15 seconds before next heading.
3. If missing: wait 30 seconds and retry once.
4. If still missing: mark heading as failed and continue.

### 5) Completion Contract

When all headings are attempted, output:

```text
YOLO COMPLETE
Topic: [topic]
Slug: [topic_slug]
Expected chunks: [N]
Written chunks: [M]
Failed chunks: [list or none]
Chunk path pattern: E:\De Anima\_tmp\[topic_slug]_chunk_[NN].md
Handoff: weaver
```

## Quality Rules

- No section should rely on another section to make sense.
- Avoid repeated paragraphs across chunks.
- Keep factual claims scoped to the heading context.
- Preserve tables, code blocks, and diagram syntax generated in chunks.

## Safety and Reliability

- Never write chunk files outside `E:\De Anima\_tmp\`.
- Never overwrite sacred files.
- Do not hang the run on single-section failure.
- Report incomplete chunk sets explicitly for weaver.

## Quick Checklist

- Pre-flight gate printed
- Heading plan finalized
- One call per heading
- 15s wait between success calls
- Retry-once with 30s wait on failure
- Completion report emitted
- Handoff to weaver
