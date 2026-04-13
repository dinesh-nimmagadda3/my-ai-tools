---
name: exec-plan
description: Load and execute a written implementation plan with review checkpoints.
license: MIT
compatibility: claude, gemini, opencode, codex
hint: Use when you have a written implementation plan to execute.
user-invocable: true
metadata:
  audience: all
  workflow: execution
---

# Executing Plans

## Overview

Load a specialized plan, review it critically, execute all tasks, and report when complete.

**Announce at start:** "I'm using the `exec-plan` skill to implement this plan."

**Note:** Work quality is significantly higher on platforms with subagent support (such as Claude Code or Codex). If subagents are available, use `subagent-dev` instead of this skill.

## The Process

### Step 1: Load and Review Plan
1. Read the plan file.
2. Review critically - identify any questions or concerns.
3. If concerns: Raise them with the user before starting.
4. If no concerns: Proceed with execution.

### Step 2: Execute Tasks
For each task:
1. Mark as `in_progress`.
2. Follow each step exactly (plans should have bite-sized steps).
3. Run verifications as specified.
4. Mark as `completed`.

### Step 3: Complete Development
After all tasks are complete and verified:
- Announce: "I'm using the `finish-branch` skill to complete this work."
- **REQUIRED SUB-SKILL:** Use `finish-branch`.
- Follow that skill to verify tests, present options, and execute choices.

## When to Stop and Ask for Help

**STOP executing immediately when:**
- You hit a blocker (missing dependency, test failure, unclear instruction).
- The plan has critical gaps preventing you from starting.
- You don't understand an instruction.
- Verification fails repeatedly.

**Ask for clarification rather than guessing.**

## Integration

**Required workflow skills:**
- `git-worktree`: Set up an isolated workspace before starting.
- `write-plan`: Creates the plan this skill executes.
- `finish-branch`: Complete development after all tasks.
