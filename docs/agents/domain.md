# Domain Docs

How the engineering skills should consume this repo's domain documentation when exploring the codebase.

## Before exploring, read these

- **`CONTEXT.md`** at the repo root.
- **`docs/adr/`** at the repo root, when present.

If any of these files don't exist, proceed silently. Don't flag their absence or suggest creating them upfront.

## File structure

This is a single-context repo:

```text
/
├── CONTEXT.md
├── docs/adr/
└── Sources/
```

## Use the glossary's vocabulary

When output names a domain concept in an issue title, refactor proposal, hypothesis, or test name, use the term as defined in `CONTEXT.md`. Don't drift to synonyms the glossary explicitly avoids.

Key terms include:

- **Localhost site**
- **Listening port**
- **Site preferences**
- **Site presentation**
- **Default view**

If the concept needed isn't in the glossary yet, note the gap rather than inventing new project vocabulary casually.

## Flag ADR conflicts

If output contradicts an existing ADR, surface it explicitly rather than silently overriding it.
