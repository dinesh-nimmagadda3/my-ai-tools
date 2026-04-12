import re

with open('README.md', 'r') as f:
    content = f.read()

# Make sure we don't accidentally wipe out the whole file.
# Remove Amp and CCS (from "## 🎯 Amp" to just before "## 🤖 OpenAI Codex CLI")
content = re.sub(r'## 🎯 Amp \(Optional\).*?(?=## 🤖 OpenAI Codex CLI \(Optional\))', '', content, flags=re.DOTALL)

# Remove Kilo CLI and everything up to "## 🛠️ Companion Tools"
content = re.sub(r'## 🎯 Kilo CLI \(Optional\).*?(?=## 🛠️ Companion Tools)', '', content, flags=re.DOTALL)

# Let's also check for Claude Code Switch in Prerequisites
content = re.sub(r'- \*\*Claude Code subscription\*\* or use \[CCS\]\(#-ccs---claude-code-switch-optional\) with affordable providers \(GLM, MiniMax\)', '- **Claude Code subscription**', content)

with open('README.md', 'w') as f:
    f.write(content)
