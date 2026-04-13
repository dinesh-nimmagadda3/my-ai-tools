---
name: git-worktree
description: Creates isolated git worktrees for parallel branch development without workspace pollution.
license: MIT
compatibility: claude, gemini, opencode, codex
hint: Use before starting new feature work that needs isolation or before executing complex plans.
user-invocable: true
metadata:
  audience: all
  workflow: git-flow
---

# Using Git Worktrees

## Overview
Git worktrees allow you to have multiple branches checked out simultaneously in different directories. This is great for fixing a bug without disturbing your current feature work.

**Core principle:** Maintain a clean workspace by isolating features into separate directories.

## Process

### 1. Identify Location
Follow this priority:
1. `.worktrees/` directory in project root (preferred).
2. `worktrees/` directory in project root.
3. If neither exists, ask the user or check `CLAUDE.md`.

### 2. Safety Check (Crucial)
If using a project-local directory (like `.worktrees/`), ensure it is ignored by git to avoid committing worktree contents:
```bash
git check-ignore -q .worktrees
```
If not ignored, add it to `.gitignore` and commit before proceeding.

### 3. Creation
Create the worktree and the new branch:
```bash
git worktree add <path> -b <branch-name>
cd <path>
```

### 4. Setup & Verification
1. **Dependencies**: Run `npm install` (or equivalent).
2. **Baseline**: Run tests (`npm test`) to ensure the worktree starts from a clean, green state.
3. **Report**: Inform the user of the new path and test status.

## Key Principles
- **Baseline matters**: know your starting point (green or red tests).
- **Isolation is safety**: don't pollute the main workspace context.
- **Cleanup**: use `finish-branch` to remove the worktree once work is integrated.
