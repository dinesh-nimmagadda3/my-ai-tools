---
name: tdd
description: Guides through the complete TDD workflow with Red-Green-Refactor cycle. Use for all features and bugfixes.
license: MIT
compatibility: claude, gemini, opencode, codex
hint: Use when doing test-driven development with Red-Green-Refactor cycle.
user-invocable: true
metadata:
  audience: all
  workflow: testing
---

# Test-Driven Development (TDD)

Guides you through the complete TDD workflow with the Red-Green-Refactor cycle.

**The Iron Law:** NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST.

## Usage

`/tdd <ACTION> [ARGUMENTS]`

### Actions
- **start <FEATURE>** - Initialize TDD session for a feature.
- **red <TEST_NAME>** - Create failing test (Red phase).
- **green** - Run tests and implement minimal code (Green phase).
- **refactor** - Improve code quality while keeping tests green (Refactor phase).
- **cycle <FEATURE>** - Run complete Red-Green-Refactor cycle.
- **watch** - Start test watcher for continuous feedback.
- **status** - Show current test status and next steps.

---

## 📐 The Red-Green-Refactor Cycle

1. **RED - Write Failing Test**: Write one minimal test showing what should happen. 
   - **Verify RED**: Watch it fail. Confirm it fails for the right reason (feature missing).
2. **GREEN - Minimal Code**: Write the simplest code to make the test pass.
   - **Verify GREEN**: Watch it pass. Ensure no regressions in other tests.
3. **REFACTOR - Clean Up**: Improve code quality, remove duplication, and improve names.

---

## 🚩 Red Flags (STOP and Start Over)
- Code written before the test.
- Test passes immediately on the first run.
- "I already manually tested it."
- "The test is too simple to write."
- "I'll add the tests after it works."

**Violating the letter of the rules is violating the spirit of the rules.**

## Common Rationalizations

| Excuse | Reality |
|--------|---------|
| "Too simple to test" | Simple code breaks. Test takes 30 seconds. |
| "I'll test after" | Tests passing immediately prove nothing. |
| "Already manually tested" | Ad-hoc != systematic. No record, can't re-run. |
| "Deleting X hours is wasteful" | Sunk cost fallacy. Unverified code is technical debt. |

## Quick Principles
- **One concept per test**: Keep tests focused and atomic.
- **AAA Pattern**: Structure tests as **Arrange, Act, Assert**.
- **Black-box testing**: Test behavior, not private implementation details.
- **Minimal Implementation**: Don't over-engineer; only code what is needed to pass.

## Verification Checklist
- [ ] Every new function has a test.
- [ ] Watched each test fail before implementing.
- [ ] Wrote minimal code to pass.
- [ ] Output is pristine (no warnings/errors).
