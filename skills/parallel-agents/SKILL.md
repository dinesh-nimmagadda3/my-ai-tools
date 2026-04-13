---
name: parallel-agents
description: Orchestrates multiple independent agents to solve unrelated problems in parallel.
license: MIT
compatibility: claude, gemini, opencode, codex
hint: Use when you have 2+ independent tasks or failures that don't share state.
user-invocable: true
metadata:
  audience: all
  workflow: orchestration
---

# Dispatching Parallel Agents

## Overview

Delegate tasks to specialized agents with isolated context to ensure focus and speed. Agents should never inherit your session's full context; instead, you construct exactly what they need.

When facing multiple unrelated failures (different subsystems, different bugs, etc.), investigating them sequentially wastes time. Each investigation should happen in parallel.

**Core principle:** Dispatch one agent per independent problem domain. Let them work concurrently.

## When to Use

Use when:
- 3+ test files are failing with different root causes.
- Multiple subsystems are broken independently.
- No shared state exists between investigations.

Don't use when:
- Failures are related (fixing one might fix others).
- You need a full system state understanding.
- Agents would interfere with each other (editing the same code sections).

## Process

1. **Identify Independent Domains**: Group failures by what's broken.
2. **Create Focused Agent Tasks**:
    - **Specific scope**: One test file or subsystem.
    - **Clear goal**: Make the specific tests pass.
    - **Expected output**: A summary of findings and fixes.
3. **Dispatch in Parallel**: Run tasks concurrently.
4. **Review and Integrate**:
    - Read agent summaries.
    - Verify fixes don't conflict.
    - Run the full test suite.
    - Integrate changes.

## Quick Tips

- **Focused Prompts**: One clear problem per agent.
- **Self-contained Context**: Provide all error logs and relevant snippets.
- **Specific Output**: Define exactly what the agent should return.
- **Avoid Vague Tasks**: "Fix everything" leads to confusion; "Fix `auth.test.ts`" leads to results.
