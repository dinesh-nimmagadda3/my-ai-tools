---
name: finish-branch
description: Guides completion of development work by presenting structured options for merge, PR, or cleanup.
license: MIT
compatibility: claude, gemini, opencode, codex
hint: Use when implementation is complete and all tests pass to decide how to integrate work.
user-invocable: true
metadata:
  audience: all
  workflow: git-flow
---

# Finishing a Development Branch

## Overview

Guide completion of development work by presenting clear options and handling the chosen workflow.

**Core principle:** Verify tests → Present options → Execute choice → Clean up.

**Announce at start:** "I'm using the `finish-branch` skill to complete this work."

## The Process

### Step 1: Verify Tests
Before presenting options, verify that all tests pass:
```bash
# Run project's test suite
npm test
```
If tests fail, you must fix them before proceeding.

### Step 2: Determine Base Branch
Identify the base branch (e.g., `main` or `master`):
```bash
git merge-base HEAD main 2>/dev/null || git merge-base HEAD master 2>/dev/null
```

### Step 3: Present Options
Present exactly these 4 options to the user:
1. **Merge back to <base-branch> locally**
2. **Push and create a Pull Request**
3. **Keep the branch as-is** (I'll handle it later)
4. **Discard this work**

### Step 4: Execute Choice
- **Option 1 (Merge)**: Switch to base, pull, merge, verify tests, delete feature branch.
- **Option 2 (PR)**: Push branch, create PR via `gh pr create`.
- **Option 3 (Keep)**: Preserve branch and worktree.
- **Option 4 (Discard)**: Require exact typed confirmation "discard" before deleting branch and worktree.

### Step 5: Cleanup Worktree
For Options 1, 2, and 4, remove the git worktree if one was used:
```bash
git worktree remove <worktree-path>
```

## Key Principles
- **Never skip test verification**: Do not merge broken code.
- **Strict options**: Present exactly 4 structured choices.
- **Safe deletion**: Always get typed confirmation before discarding work.
- **Cleanup**: Manage worktrees responsibly.
