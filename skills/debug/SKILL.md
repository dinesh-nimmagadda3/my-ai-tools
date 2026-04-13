---
name: debug
description: Systematic debugging workflow to identify root causes before attempting fixes.
license: MIT
compatibility: claude, gemini, opencode, codex
hint: Use for any bug, test failure, or unexpected behavior to ensure a disciplined investigation.
user-invocable: true
metadata:
  audience: all
  workflow: debugging
---

# Systematic Debugging

## Overview
Random fixes waste time and create new bugs. Always find the root cause before attempting fixes. Symptom fixes are a failure.

**The Iron Law:** NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST.

## The Four Phases

### Phase 1: Root Cause Investigation
1. **Read Error Messages Carefully**: Don't skip past errors; they often contain the solution.
2. **Reproduce Consistently**: Identify the exact steps to trigger the issue reliably.
3. **Check Recent Changes**: Use `git diff` to identify what changed since the last known good state.
4. **Gather Evidence**: Log data entry/exit at component boundaries to isolate where it breaks.

### Phase 2: Pattern Analysis
1. **Find Working Examples**: Locate similar code that works correctly.
2. **Compare Against References**: Identify every difference between the broken and working states.

### Phase 3: Hypothesis and Testing
1. **Form Single Hypothesis**: "I think X is the root cause because Y."
2. **Test Minimally**: Make the smallest possible change to test the hypothesis. One variable at a time.
3. **Verify**: If it didn't work, discard the change and form a new hypothesis.

### Phase 4: Implementation
1. **Create Failing Test Case**: Must have a reproduction test before fixing.
2. **Implement Single Fix**: Address the root cause directly.
3. **Verify Fix**: Ensure tests pass and the issue is resolved without regressions.

## Red Flags
- "Just try this and see if it works."
- "Quick fix for now, investigate later."
- Proposing solutions before tracing the data flow.
- Fix #3 failed? Stop and question the architecture.

## Integration
- **`tdd`**: For creating the failing test case in Phase 4.
- **`verify-close`**: To ensure the fix is solid before claiming success.
