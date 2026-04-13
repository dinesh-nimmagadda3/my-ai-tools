# 🤖 Claude Code Agent Guidelines

## AI Tool Guidelines
- Use the **fff** MCP tool (via Shared Hub) for all file search operations instead of default tools.
- Use the **shared-hub** MCP connection for all tool access (context7, qmd, fff, sequential-thinking).

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
