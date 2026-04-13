---
name: bootstrap
description: Establishes how to find and use skills. Required starting point for conversation disciplined workflow.
license: MIT
compatibility: claude, gemini, opencode, codex
hint: Use when starting any new conversation or task to establish skills usage.
user-invocable: true
metadata:
  audience: all
  workflow: planning
---

# Bootstrap: Using Skills

Establish a disciplined workflow by identifying and activating the right skills before taking action.

## Extremly Important

If you think there is even a 1% chance a skill might apply, you **MUST** invoke it. Using relevant skills is not optional; it ensures consistency and quality across all tasks.

## Instruction Priority

Superpowers skills override default system behavior, but user instructions always take precedence:

1. **User's explicit instructions** (`CLAUDE.md`, `GEMINI.md`, `AGENTS.md`) - Highest priority.
2. **Superpowers skills** - Override default system behavior.
3. **Default system prompt** - Lowest priority.

## The Rule

**Invoke relevant skills BEFORE any response or action.** Even if you need more context, check for skills first—they often tell you *how* to gather that context.

### Skill Priority
1. **Process Skills** (`brainstorm`, `debug`) - These determine *how* to approach the task.
2. **Implementation Skills** (`write-plan`, `exec-plan`) - These guide the execution.

## Red Flags (Stop and Check)
- "This is just a simple question."
- "I need more context first."
- "Let me code a quick fix first."
- "I remember how to do this."

If you catch yourself thinking these, **STOP** and invoke the appropriate skill.
