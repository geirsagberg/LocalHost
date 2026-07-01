# AGENTS.md instructions

- When asked to reproduce a bug/error in a test, assert the intended/wanted behavior (not the current buggy behavior), even if the test fails until the fix is implemented.
- Preserve meaningful existing comments; only remove or rewrite comments when they are clearly obsolete, incorrect, or redundant after code changes.
- Never include a `Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>` trailer in git commit messages.
- Only add a co-author trailer if explicitly asked for one and provided the exact trailer text to use.

## Agent skills

### Issue tracker

Issues and PRDs are tracked in GitHub Issues for `geirsagberg/LocalHost`. See `docs/agents/issue-tracker.md`.

### Triage labels

Use the canonical triage label vocabulary: `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, and `wontfix`. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context repo: read root `CONTEXT.md` for domain language and root `docs/adr/` for architectural decisions when present. See `docs/agents/domain.md`.
