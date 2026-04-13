# 🤖 Gemini CLI Agent Guidelines

## 🛠️ AI Tooling
- **Shared Hub (V5)**: Use the `hub` or `shared-hub` connection (localhost:5115) to access all tools.
- **MCP Servers**: Use `fff` (search), `context7` (docs), `qmd` (knowledge), `memory` (graph), `filesystem` (access), and `chrome-devtools` (browser).
- **Skills (22 Built-in)**: Check `skills/` for instruction sets. Activate via `activate_skill`.
    - **MANDATORY**: Use the `bootstrap` skill at the start of any new mission or session.
    - **Workflow**: Follow `brainstorm` → `write-plan` → `subagent-dev` for major features.
    - **Quality**: Always use `verify-close` before claiming a task is done.

## General Practices
- Follow my software development practice @~/.ai-tools/best-practices.md
- Follow git safety guidelines @~/.ai-tools/git-guidelines.md
- Keep responses concise and actionable.
- Always propose a plan before edits. Use phases to break down tasks into manageable steps.
- Run typecheck, lint and biome on js/ts file changes after finish.
- Prefer to use **Bun** to run scripts if possible (`bun run`, `bun test`), otherwise use `tsx` for .ts files.
- Never run destructive commands.
- Use our conventions for file names, tests, and commands.
- Keep your code clean and organized. Do not over-engineer or overcomplicate things unnecessarily.
- Write clear and concise code. Avoid unnecessary complexity and redundancy.
- Use meaningful variable and function names.
- Prefer self-documenting code. Write comments and documentation where necessary.
- Keep your code modular and reusable. Avoid tight coupling and excessive dependencies.
