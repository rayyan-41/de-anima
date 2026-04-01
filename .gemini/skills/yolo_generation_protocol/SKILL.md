---
name: yolo_generation_protocol
description: "The strict recursive sub-session rules for generating large structural files."
---

# YOLO Generation Protocol

## Purpose
This skill forces the AI into a specific algorithmic loop for writing notes section-by-section using discrete, background sub-sessions. It ensures the vault avoids token context limits and API rate-listing boundaries on long documents.

## Execution Rules

### 1. Planning the Note Architecture

When a user provides a topic, draft an internal outline first (15+ sections).
- Calculate total word count target (Section count * 1000).
- Confirm the operation to the user before generating.

### 2. The Generation Loop (Mandatory API Logic)

For **every** section in your architecture outline, do the following:

**Step A:** Trigger a new sub-session specifically scoped on the single section.
**Step B:** The context payload for this task must follow the prompt rules mapping directly to the target domain, but the response size must fill the sub-task target (1,000 words).
**Step C:** Write the output to a unique temporary file located in `E:\De Anima\_tmp\`.
   - File format: `E:\De Anima\_tmp\[topic-slug]_chunk_[NN].md`
   - Example: `E:\De Anima\_tmp\ghusl_chunk_01.md`
**Step D (MANDATORY)**: After completing the section and writing the file, you must execute a strict 15-second sleep to prevent rate limiting:

```powershell
Start-Sleep -Seconds 15
```

**Step E**: Proceed to the next section and run Step A again.

### 3. Assembly Hand-off

Once all sections have been generated into the `_tmp/` folder, the generation phase ends. DO NOT compile them yourself. Your only job is writing sub-pieces.
- Signal to the Orchestrator/user that generation is complete.
- State: `All chunks written to E:\De Anima\_tmp\. Instructing @weaver to compile.`
- De-reference execution to the `@weaver` agent.
