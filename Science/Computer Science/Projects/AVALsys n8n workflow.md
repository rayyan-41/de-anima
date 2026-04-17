---
date: 2026-04-05
status: complete
tags: [science, computer-science, computation, algorithms, engineering, cli, ai-generated]
note: ""
---

The **AVALsys Project** is an AI-native financial reconciliation engine engineered specifically for the chaotic reality of the Pakistani B2B market. We are building a system that can "read" messy bank PDFs, Roman Urdu descriptions (e.g., _"Paisa mil gaya"_), and informal ledgers to autonomously match transactions with high precision.

### The Tech Stack & "The Why"

We are using a **"Yolo" Architecture**—not because it's reckless, but because it's the fastest, most sovereign way to ship a CV-worthy product in 2026:

- **Orchestration: n8n (Self-Hosted)** – Unlike Zapier, n8n gives us infinite "task" scaling for free and keeps sensitive Pakistani financial data on our own servers.
- **Intelligence: [[GEMINI|Gemini]] 3 Pro** – It provides "Vision" for messy PDFs and "Reasoning" for Roman Urdu that standard models miss.
- **State: Supabase (Postgres)** – We need the ACID compliance of SQL for accounting; a "reconciliation" must either happen completely or not at all.
- **Memory: pgvector** – By storing "Vendor Aliases" as vectors, we can semantically match "K-Electric" to "KE-BILL-MAY" without writing a thousand `if` statements.
### Architecture & Workflow

We’ve rejected "Monolithic Workflows" in favor of a **Modular Agentic Pipeline**:

1. **Ingestion Tier (The Harvester):** We split PDFs into pages to prevent n8n memory crashes, use Gemini 3 to "see" the transaction tables, and dump the raw results into a **Staging Table**.
2. **Reasoning Tier (The Brain):** An agent pulls from staging, queries the vector database for vendor matches, and assigns a **Confidence Score**.
3. **Settlement Tier (The Sealer):** If the score is $>0.9$, it auto-commits the transaction to the main ledger. Anything lower is flagged for human review.

This approach ensures that even if the AI "vibes" the description, the **Audit Trail** and **SQL Constraints** keep the accounting technically rigorous.

## See Also

- [[GEMINI]] — Concept referenced in text.
- [[_Science - Map of Contents|Science MOC]]
