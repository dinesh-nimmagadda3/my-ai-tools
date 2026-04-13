---
name: verify-close
description: Mandatory verification of completion claims with evidence before asserting work is finished.
license: MIT
compatibility: claude, gemini, opencode, codex
hint: Use before claiming any task is done, fixed, or passing to ensure evidence-based results.
user-invocable: true
metadata:
  audience: all
  workflow: quality-assurance
---

# Verification Before Completion (Verify-Close)

Claiming work is complete without verification is dishonesty, not efficiency.

**The Iron Law:** NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE.

## The Gate Function

BEFORE claiming any status or expressing satisfaction:

1. **IDENTIFY**: What command proves this claim? (Tests, linter, build logs).
2. **RUN**: Execute the FULL command fresh.
3. **READ**: Analyze the full output, check exit codes, and count failures.
4. **VERIFY**: Does the output confirm the claim exactly?
5. **ONLY THEN**: Make the success claim with the attached evidence.

## Common Failures to Avoid

- **"Should pass"**: Not a verification. Run it.
- **"Tests passed earlier"**: Re-run them now to ensure no regressions.
- **"Linter is clean"**: Doesn't mean the code compiles or works.
- **"Fixed in code"**: Must be verified with a reproduction test.

## Key Patterns

### Tests
- ✅ "All tests pass (34/34)" [Output: 0 failures]
- ❌ "Looks correct for now"

### Requirements
- ✅ Re-read the plan → Create a checklist → Verify each item → Report results.
- ❌ "Phase complete" based on intuition.

## Red Flags
- Using "should", "probably", or "seems to".
- Proposing PRs without the final test run.
- Trusting subagent success reports without checking the diff.

**Evidence before assertions, always.**
