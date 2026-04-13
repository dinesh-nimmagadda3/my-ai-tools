---
name: pr-review
description: Complete Pull Request lifecycle including requesting reviews, receiving feedback, and implementing fixes.
license: MIT
compatibility: claude, gemini, opencode, codex
hint: Use when requesting a code review or once feedback has been received on a PR.
user-invocable: true
metadata:
  audience: all
  workflow: quality-assurance
---

# PR Review Lifecycle

Manage the complete code review process: from requesting a review to implementing feedback with technical rigor.

## 🏁 Requesting Code Review
Review early, review often. Catch issues before they cascade.

**When to Request:**
- After each task in `subagent-dev`.
- After completing a major feature.
- Before merging to `main`.

**Process:**
1. **Identify Changes**: Get the git SHAs (`BASE_SHA` and `HEAD_SHA`).
2. **Dispatch Reviewer**: Use a specialized reviewer subagent (if available) with the specific task scope.
3. **Act on Feedback**: Fix **Critical** and **Important** issues before proceeding.

---

## 📥 Receiving Feedback
Technical correctness > performance of politeness. Verify. Question. Then implement.

**The Golden Rules:**
- **No Performative Agreement**: Do NOT say "You're absolutely right!" or "Thanks for the suggestion!" Just state the fix or push back with reasoning.
- **Clarify First**: If feedback on multiple items is given, clarify anything unclear BEFORE starting implementation.
- **Verify Suggestions**: Check if the reviewer's suggestion is technically correct for *this* stack and doesn't break existing functionality.
- **Push Back**: If a suggestion is wrong, lacks context, or violates YAGNI (unused functionality), push back with technical reasoning.

---

## 🛠️ Implementing Fixes
Use the built-in tooling to prioritize and execute feedback.

**Usage:**
```bash
/pr-review <PR_URL>      # Auto-detects and extracts comments
/pr-review <PR_NUMBER>   # Processes a specific PR
```

**Workflow:**
1. **Extract**: Fetch comments using `gh pr view --comments`.
2. **Categorize**: Use `extract-pr-comments.js` to create a prioritized TODO list.
3. **Fix**: Implement changes in order of severity (Critical → High → Medium → Low).
4. **Verify**: Run tests after every fix.
5. **Report**: State the fix factually: "Fixed. Extracted logic to `auth.js` helper."

## Red Flags
- Skipping review because "it's just a small change."
- Blindly implementing every suggestion without checking correctness.
- Saying "Thanks" instead of proving the fix works.
- Proposing fixes without understanding the full feedback.
