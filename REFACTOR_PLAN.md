# Project Refactor Plan — supreme-succotash

**Date:** 2026-08-01
**Branch:** `claude/project-refactor-plan-r4fj1g`
**Status:** Ready for review

---

## 1. Where the Project Stands Today (Honest Audit)

Before planning a refactor, I audited the repository. Here is the full inventory:

| Item | Status |
|------|--------|
| Source code | **None** — the repository contains no application code |
| `CLAUDE.md` | Present — an AI-assistant guide template, mostly placeholder sections marked "TBD" |
| Tests | None |
| Build config / dependencies | None (no `package.json`, `requirements.txt`, etc.) |
| README | None |
| CI/CD | None |

**Key finding: there is currently nothing to refactor.** The repository is an empty
shell with a documentation template. This is important to say plainly, because it
changes what "refactor" means here — the real task is to **bootstrap the project
properly from day one** so it never *needs* a painful refactor later.

If you believe there should be code in this repository, it may live somewhere else
(another repo, a local folder that was never pushed, or a different branch on a
different account). Step 1 below covers resolving that.

---

## 2. Decisions Needed From You (blocking — answer these first)

These are the only things I cannot decide alone. Everything after this section
proceeds without you once these are answered.

1. **Where is the code?** Is there existing code that belongs in this repo
   (local machine, another repo)? If yes, push it or tell me where it is and
   I'll pull it in. If no, confirm we're starting fresh.
2. **What is the project?** One or two sentences: what should this software do,
   and who uses it?
3. **Stack preference?** If you have one (Python, JavaScript/TypeScript, etc.),
   say so. If not, I'll choose based on the answer to #2 and justify the choice.

---

## 3. The Plan (phased, each phase ends in a pushed, reviewable state)

### Phase 0 — Resolve the decisions above
- You answer the three questions in Section 2 (a couple of sentences is enough).
- If existing code surfaces, I audit it and produce a *real* refactor plan for it
  as an addendum to this document.

### Phase 1 — Foundation (first working day after Phase 0)
- Add a `README.md` describing the project's purpose.
- Scaffold the project structure: `src/`, `tests/`, `docs/`, `scripts/`.
- Add dependency manifest, `.gitignore`, formatter + linter config.
- Rewrite `CLAUDE.md`: delete every "TBD" placeholder and fill it with the real
  stack, real commands, and real conventions (it's currently ~80% empty template).

### Phase 2 — Core implementation
- Build the first vertical slice of the actual feature set from Section 2.
- Every piece lands with unit tests from the start — no "add tests later."

### Phase 3 — Quality gates
- CI via GitHub Actions: lint + test on every push.
- Branch protection recommendation for `main` once CI is green.

### Phase 4 — Iterate
- Feature work proceeds in small PRs, each reviewable in minutes, not hours.

---

## 4. How We Communicate in Near-Real-Time

You asked how to respond quickly and keep this moving:

- **Fastest: reply in the Claude Code session** (claude.ai/code on web or the
  mobile app). The session runs in the cloud — your computer locking or sleeping
  does not stop it. Messages you send arrive while I'm working.
- **GitHub**: comments on commits/PRs in this repo reach me when I'm subscribed
  to the PR. Once a PR exists, I can watch it and respond to every comment and
  CI failure automatically.
- **Email**: a draft summarizing this plan is in your Gmail drafts — you can
  send/forward it (e.g., to Monica) for a second pair of eyes.
- **SMS**: I don't have a text-messaging capability, so I can't text
  336.391.8120 directly. Push notifications through the Claude app are the
  closest equivalent, and I've sent one for this plan.

---

## 5. What Happens Next

Reply (in the session, or a GitHub comment) with answers to Section 2's three
questions. I'll start Phase 1 the same day and push it to this branch for review.
