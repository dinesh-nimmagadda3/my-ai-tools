---
name: subagent-dev
description: Execute an implementation plan by dispatching focused subagents for each task with specialized review loops.
license: MIT
compatibility: claude, gemini, opencode, codex
hint: Use when you have a plan and want to delegate tasks to isolated subagents for high-quality execution.
user-invocable: true
metadata:
  audience: all
  workflow: execution
---

# Subagent-Driven Development

Execute a plan by dispatching a fresh subagent per task, with a two-stage review after each: spec compliance first, then code quality.

## Core Principle
**Fresh Subagent per Task** + **Two-Stage Review** (Spec then Quality) = High Quality, Fast Iteration.

## The Process

1. **Extraction**: Read the plan, extract all tasks with full text, and create a tracking checklist.
2. **Dispatch Implementer**: For each task, dispatch a fresh subagent with the specific task scope and context.
3. **Spec Review**: Once implemented, dispatch a reviewer subagent to confirm the code matches the spec exactly.
4. **Quality Review**: After spec approval, dispatch a reviewer subagent to ensure high code quality and pattern consistency.
5. **Completion**: Mark the task as complete and move to the next.
6. **Final Integration**: After all tasks, run a final review and use `finish-branch`.

## Handling Implementer Status
- **DONE**: Proceed to review.
- **NEEDS_CONTEXT**: Provide missing info and re-dispatch.
- **BLOCKED**: Identify the blocker. If the task is too large, decompose it. If the plan is wrong, update it.

## Key Rules
- **One task at a time**: Don't dispatch multiple implementers in parallel to avoid conflicts.
- **Strict reviews**: No skipping spec or quality checks.
- **Answer questions**: If a subagent asks for clarification, provide it before they proceed.
- **Use TDD**: Subagents should follow Test-Driven Development for each task.

## Integration
- **`write-plan`**: Creates the plan this skill executes.
- **`finish-branch`**: Complete development after all tasks.
- **`tdd`**: Followed by subagents for each task.
