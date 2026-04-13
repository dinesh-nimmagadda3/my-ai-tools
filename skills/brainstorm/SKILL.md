---
name: brainstorm
description: Explores user intent, requirements, and design before implementation. Required before creative work.
license: MIT
compatibility: claude, gemini, opencode, codex
hint: Use before starting any new feature or modification to explore intent and design.
user-invocable: true
metadata:
  audience: all
  workflow: planning
---

# Brainstorming Ideas Into Designs

Help turn ideas into fully formed designs and specs through natural collaborative dialogue.

Start by understanding the current project context, then ask questions one at a time to refine the idea. Once you understand what you're building, present the design and get user approval.

<HARD-GATE>
Do NOT invoke any implementation skill, write any code, scaffold any project, or take any implementation action until you have presented a design and the user has approved it. This applies to EVERY project regardless of perceived simplicity.
</HARD-GATE>

## Anti-Pattern: "This Is Too Simple To Need A Design"

Every project goes through this process. A todo list, a single-function utility, a config change — all of them. "Simple" projects are where unexamined assumptions cause the most wasted work. The design can be short (a few sentences for truly simple projects), but you MUST present it and get approval.

## Checklist

You MUST create a task for each of these items and complete them in order:

1. **Explore project context** — check files, docs, recent commits
2. **Offer visual companion** (if topic will involve visual questions) — this is its own message, not combined with a clarifying question.
3. **Ask clarifying questions** — one at a time, understand purpose/constraints/success criteria
4. **Propose 2-3 approaches** — with trade-offs and your recommendation
5. **Present design** — in sections scaled to their complexity, get user approval after each section
6. **Write design doc** — save to `docs/specs/YYYY-MM-DD-<topic>-design.md` and commit
7. **Spec self-review** — quick inline check for placeholders, contradictions, ambiguity, scope
8. **User reviews written spec** — ask user to review the spec file before proceeding
9. **Transition to implementation** — invoke `write-plan` skill to create implementation plan

## Process Flow

1. Check out the current project state (files, docs, recent commits).
2. For appropriately-scoped projects, ask questions one at a time to refine the idea.
3. Propose 2-3 different approaches with trade-offs.
4. Once you believe you understand what you're building, present the design.
5. Cover: architecture, components, data flow, error handling, testing.
6. Write the validated design (spec) to `docs/specs/YYYY-MM-DD-<topic>-design.md`.
7. Ask the user to review the written spec before proceeding.
8. Invoke the `write-plan` skill to create a detailed implementation plan.

## Key Principles

- **One question at a time** - Don't overwhelm with multiple questions.
- **Multiple choice preferred** - Easier to answer than open-ended when possible.
- **YAGNI ruthlessly** - Remove unnecessary features from all designs.
- **Explore alternatives** - Always propose 2-3 approaches before settling.
- **Incremental validation** - Present design, get approval before moving on.
