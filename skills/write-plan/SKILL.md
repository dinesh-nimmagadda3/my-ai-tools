---
name: write-plan
description: Transforms a spec into a comprehensive, task-by-task implementation plan with TDD focus.
license: MIT
compatibility: claude, gemini, opencode, codex
hint: Use when you have a spec or requirements for a multi-step task, before touching any code.
user-invocable: true
metadata:
  audience: all
  workflow: planning
---

# Writing Plans

Write comprehensive implementation plans that decompose a design into bite-sized, testable tasks. Assume the engineer knows almost nothing about the project context or domain.

**Announce at start:** "I'm using the `write-plan` skill to create the implementation plan."

**Save plans to:** `docs/plans/YYYY-MM-DD-<feature-name>.md`

## The Process

### 1. File Structure Mapping
Map out exactly which files will be created or modified and their clear responsibilities. Favor small, focused files over large ones.

### 2. Task Decomposition
Break the implementation into action-oriented tasks (2-5 minutes each). Each task should follow the TDD cycle:
1. **Red**: Write a failing test.
2. **Green**: Write minimal code to make it pass.
3. **Refactor**: Improve code quality.
4. **Commit**: Capture progress.

### 3. No Placeholders
Every task must contain the full context needed for an engineer to execute it. Avoid "TBD", "TBD", or "implement later". Every code change should be clearly defined.

### 4. Self-Review
Before finalizing, check your plan for:
- **Spec Coverage**: Is every requirement in the spec covered by a task?
- **Consistency**: Do function names and signatures match across all tasks?
- **Redundancy**: Any unnecessary work that violates YAGNI?

## Plan Document Template

```markdown
# [Feature Name] Implementation Plan

**Goal**: [One sentence goal]
**Architecture**: [High-level approach]

---

### Task 1: [Component Name]
**Files**: `src/path/file.py`, `tests/path/test_file.py`

- [ ] **Step 1: Write failing test**
[Code Block Here]

- [ ] **Step 2: Verify failure**
Run: `npm test` | Expected: Fail (0 passing)

- [ ] **Step 3: Implementation**
[Code Block Here]

- [ ] **Step 4: Verify pass**
Run: `npm test` | Expected: Pass (1 passing)

- [ ] **Step 5: Commit**
`git add ... && git commit -m "feat: add component"`
```

## Execution Options
After the plan is approved, offer two paths:
1. **Subagent-Driven** (Recommended): Dispatch focused subagents per task using `subagent-dev`.
2. **Inline Execution**: Execute tasks sequentially in the current session using `exec-plan`.
