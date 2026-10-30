# Project wiki — MUST DO on every action

Adapted from Karpathy's LLM Wiki pattern
(<https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f>).
`wiki/` is a persistent, compounding knowledge base that Claude maintains.
Knowledge is written down once and kept current, not re-derived each session.

## Three layers

| Layer | What | Who edits |
|-------|------|-----------|
| **Raw sources** | Code, `docs/`, READMEs, external URLs, and facts the user states in chat | Immutable from the wiki's side: pages cite them, never copy them wholesale |
| **Wiki** | `wiki/**/*.md`: synthesized pages about features, components, concepts, ops and decisions | Claude writes; the user curates |
| **Schema** | This file + `CLAUDE.md` (or `AGENTS.md`) | Change only when the user asks |

## Every task: Query → Work → Ingest

1. **Query (before acting).** Read `wiki/index.md`, then the pages relevant to
   the task. If a page contradicts the code, the code wins: fix the page in step 3.
2. **Work.** Do the task. If something fails or surprises you, check the wiki
   for a known issue before debugging from scratch.
3. **Ingest (before the final reply).** For anything durable you learned or changed:
   - Update the relevant page(s), or create one (search the index first).
   - Add or refresh the page's line in `wiki/index.md`.
   - Append one entry to `wiki/log.md`.
   - Run `python3 scripts/wiki-lint.py` and fix all errors.

Skip ingest for things that aren't durable (typo fixes, throwaway commands).
Append a `query` log line when an answer was synthesized from the wiki.
Grow the wiki from real work only; never document the whole repo up front.

## Page format

```markdown
---
title: Short title
type: overview | feature | component | concept | entity | source | ops | decision | query | synthesis
sources:
  - path/in/repo.ext
  - https://example.com/doc
  - user (YYYY-MM-DD)
updated: YYYY-MM-DD
---

# Short title

Body. Cross-link with relative links: [other page](../concepts/other.md).
```

- `sources`: repo paths (must exist; lint checks), URLs, or `user (YYYY-MM-DD)`.
- `updated`: when the wiki learned it. Put when a fact held in the text.
- **Superseded, not deleted.** Strike through and add the replacement with a date.
- **Flag contradictions** inline as `> ⚠ Conflict: …` until resolved.
- Keep pages short and factual; link to `docs/` for how-tos.

## Special files

- `wiki/index.md`: catalog grouped by category, one line per page:
  `- [Title](path.md) — one-line summary`. Every page must be listed.
- `wiki/log.md`: append-only, newest at the bottom. Never rewrite past entries.
  `## [YYYY-MM-DD] ingest|query|lint|decision | short title`, then 1–3 bullets.

## Lint

`scripts/wiki-lint.py` checks frontmatter, index coverage, broken links,
missing source paths and log format. Run it at the end of every ingest. On a
user-requested health check, also review for stale claims, contradictions,
orphans and gaps, and log a `lint` entry.
