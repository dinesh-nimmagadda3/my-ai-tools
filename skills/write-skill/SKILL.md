---
name: write-skill
description: Use when creating new skills, editing existing skills, or verifying skill effectiveness.
license: MIT
compatibility: claude, gemini, opencode, codex
hint: Use when you want to extend the AI's capabilities with a new persistent skill or mental model.
user-invocable: true
metadata:
  audience: all
  workflow: evolution
---

# Writing Skills

**Writing skills is Test-Driven Development applied to process documentation.**

You write test cases (pressure scenarios), watch them fail (baseline behavior), write the skill (documentation), watch tests pass (agents comply), and refactor (close loopholes).

**Core principle:** If you didn't watch an agent fail without the skill, you don't know if the skill teaches the right thing.

## The Rule: No Skill Without a Failing Test First

This applies to NEW skills AND EDITS to existing skills.

## SKILL.md Standard Format

All skills in this toolkit MUST follow this metadata structure:

```markdown
---
name: skill-name-with-hyphens
description: Use when [specific triggering conditions and symptoms]
license: MIT
compatibility: claude, gemini, opencode, codex
hint: Short mnemonic for tool search
user-invocable: true
metadata:
  audience: all
  workflow: category
---

# Skill Name
## Overview
## When to Use
## Process
## Key Principles
```

## Discovery Optimization
1. **Rich Description**: Start with "Use when..." and focus on triggering conditions. Do NOT summarize the workflow in the description (Claude might skip the skill content).
2. **Shortened Names**: Use active, verb-first names (e.g., `write-skill` not `skill-writing`).
3. **Keyword Density**: Include error messages and symptoms Claude would search for.

## Loophole Proofing
- Close explicitly: Don't just say "Do X," say "Don't do Y instead."
- Addressing Spirit vs Letter: Include aFoundational Principle early: "Violating the letter of the rules is violating the spirit of the rules."

## Deployment Checklist
- [ ] Create pressure scenario.
- [ ] Run without skill (document failure).
- [ ] Write minimal skill addressing failure.
- [ ] Run with skill (verify compliance).
- [ ] Refactor to close new loopholes.
- [ ] Update `README.md` skills table.
