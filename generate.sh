#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
DRY_RUN=false

for arg in "$@"; do
	case $arg in
	--dry-run)
		DRY_RUN=true
		shift
		;;
	*)
		echo "Unknown option: $arg"
		echo "Usage: $0 [--dry-run]"
		exit 1
		;;
	esac
done



copy_single() {
	local src="$1"
	local dest="$2"
	if [ -f "$src" ]; then
		execute "mkdir -p $(dirname "$dest")"
		execute "cp \"$src\" \"$dest\""
		log_success "Copied: $src → $dest"
	else
		log_warning "Skipped (not found): $src"
	fi
}

copy_directory() {
	local src="$1"
	local dest="$2"
	if [ -d "$src" ]; then
		execute "mkdir -p '$dest'"
		execute "cp -r '$src'/* '$dest'/ 2>/dev/null || true"
		log_success "Copied directory: $src → $dest"
	else
		log_warning "Skipped (not found): $src"
	fi
}



# Copy a Claude subdirectory with proper logging
# Usage: copy_claude_subdirectory "source_path" "dest_path" "name_for_logging"
copy_claude_subdirectory() {
	local src="$1"
	local dest="$2"
	local name="$3"

	if [ ! -d "$src" ]; then
		return 0
	fi

	if [ -z "$(ls -A "$src" 2>/dev/null)" ]; then
		log_warning "Claude $name directory is empty"
		return 0
	fi

	execute "mkdir -p '$dest'"
	if execute "cp -r '$src'/* '$dest'/ 2>/dev/null"; then
		log_success "Copied $name directory"
	else
		log_warning "Failed to copy $name directory"
	fi
}

# Copy skills
# Usage: copy_skills "source_dir" "dest_dir" "tool_name"
copy_skills() {
	local source_dir="$1"
	local dest_dir="$2"
	local tool_name="${3:-Claude Code}"

	if [ ! -d "$source_dir" ]; then
		return 0
	fi

	if [ -z "$(ls -A "$source_dir" 2>/dev/null)" ]; then
		log_warning "$tool_name skills directory is empty"
		return 0
	fi

	execute "mkdir -p '$dest_dir'"
	execute "cp -r '$source_dir'/* '$dest_dir'/ 2>/dev/null || true"
}

generate_claude_configs() {
	log_info "Generating Claude Code configs..."

	if [ ! -d "$HOME/.claude" ]; then
		log_warning "Claude Code config directory not found: $HOME/.claude"
		return 0
	fi

	execute "mkdir -p $SCRIPT_DIR/configs/claude"

	# Copy core files
	copy_single "$HOME/.claude/CLAUDE.md" "$SCRIPT_DIR/configs/claude/CLAUDE.md"

	# Copy subdirectories
	copy_claude_subdirectory "$HOME/.claude/commands" "$SCRIPT_DIR/configs/claude/commands" "commands"
	copy_claude_subdirectory "$HOME/.claude/agents" "$SCRIPT_DIR/configs/claude/agents" "agents"
	copy_claude_subdirectory "$HOME/.claude/hooks" "$SCRIPT_DIR/configs/claude/hooks" "hooks"
	copy_skills "$HOME/.claude/skills" "$SCRIPT_DIR/configs/claude/skills" "Claude Code"

	# Copy claude.json (with Windows path fix)
	copy_claude_settings

	log_success "Claude Code configs generated"
}

copy_claude_settings() {
	local settings_source=""

	if [ "$IS_WINDOWS" = true ]; then
		# Windows: Claude Code uses ~/.claude directly
		settings_source="$HOME/.claude/claude.json"
	else
		# Mac/Linux: Check canonical location first
		if [ -f "$HOME/.claude/claude.json" ]; then
			settings_source="$HOME/.claude/claude.json"
		elif [ -f "$HOME/.config/claude/claude.json" ]; then
			settings_source="$HOME/.config/claude/claude.json"
			log_warning "Using XDG config path (older configuration detected)"
		else
			log_warning "claude.json not found in ~/.claude/ or ~/.config/claude/"
		fi
	fi

	if [ -n "$settings_source" ]; then
		copy_single "$settings_source" "$SCRIPT_DIR/configs/claude/claude.json"
	fi
}

generate_opencode_configs() {
	log_info "Generating OpenCode configs..."

	if [ ! -d "$HOME/.config/opencode" ]; then
		log_warning "OpenCode config directory not found: $HOME/.config/opencode"
		return 0
	fi

	execute "mkdir -p $SCRIPT_DIR/configs/opencode"

	# Copy and clean opencode.json (strip local-only providers like ollama)
	if [ -f "$HOME/.config/opencode/opencode.json" ]; then
		if command -v jq &>/dev/null; then
			execute "jq 'del(.provider)' \"$HOME/.config/opencode/opencode.json\" > \"$SCRIPT_DIR/configs/opencode/opencode.json\""
			log_success "Generated and cleaned opencode.json (removed local providers)"
		else
			copy_single "$HOME/.config/opencode/opencode.json" "$SCRIPT_DIR/configs/opencode/opencode.json"
		fi
	fi

	# Copy tui.json
	copy_single "$HOME/.config/opencode/tui.json" "$SCRIPT_DIR/configs/opencode/tui.json"

	# Copy skills
	copy_skills "$HOME/.config/opencode/skills" "$SCRIPT_DIR/configs/opencode/skills" "OpenCode"

	# Copy agents and configs directories
	for subdir in agents configs; do
		if [ -d "$HOME/.config/opencode/$subdir" ]; then
			execute "mkdir -p $SCRIPT_DIR/configs/opencode/$subdir"
			if [ -n "$(ls -A "$HOME/.config/opencode/$subdir" 2>/dev/null)" ]; then
				if execute "cp -r '$HOME/.config/opencode/$subdir'/* '$SCRIPT_DIR/configs/opencode/$subdir'/ 2>/dev/null"; then
					log_success "Copied $subdir directory"
				fi
			fi
		fi
	done

	# Copy commands (skip ai/ folder which is generated from local skills)
	if [ -d "$HOME/.config/opencode/commands" ]; then
		execute "mkdir -p $SCRIPT_DIR/configs/opencode/commands"
		if [ -n "$(ls -A "$HOME/.config/opencode/commands" 2>/dev/null)" ]; then
			for item in "$HOME/.config/opencode/commands"/*; do
				local item_name
				item_name=$(basename "$item")
				if [ "$item_name" = "ai" ]; then
					log_info "Skipping ai/ command folder (generated from local skills)"
				elif execute "cp -r '$item' '$SCRIPT_DIR/configs/opencode/commands'/ 2>/dev/null"; then
					log_success "Copied command: $item_name"
				fi
			done
		fi
	fi

	log_success "OpenCode configs generated"
}


generate_codex_configs() {
	log_info "Generating Codex CLI configs..."

	if [ ! -d "$HOME/.codex" ]; then
		log_warning "Codex CLI config directory not found: $HOME/.codex"
		return 0
	fi

	execute "mkdir -p $SCRIPT_DIR/configs/codex"
	copy_single "$HOME/.codex/AGENTS.md" "$SCRIPT_DIR/configs/codex/AGENTS.md"
	copy_single "$HOME/.codex/config.toml" "$SCRIPT_DIR/configs/codex/config.toml"

	log_success "Codex CLI configs generated"
}

generate_gemini_configs() {
	log_info "Generating Gemini CLI configs..."

	if [ ! -d "$HOME/.gemini" ]; then
		log_warning "Gemini CLI config directory not found: $HOME/.gemini"
		return 0
	fi

	execute "mkdir -p $SCRIPT_DIR/configs/gemini"

	# Copy core files
	copy_single "$HOME/.gemini/AGENTS.md" "$SCRIPT_DIR/configs/gemini/AGENTS.md"
	copy_single "$HOME/.gemini/settings.json" "$SCRIPT_DIR/configs/gemini/settings.json"
	copy_single "$HOME/.gemini/GEMINI.md" "$SCRIPT_DIR/configs/gemini/GEMINI.md"

	# Copy agents directory (check both 'agents' and 'agent' for backward compat)
	for src_dir in agents agent; do
		if [ -d "$HOME/.gemini/$src_dir" ]; then
			copy_claude_subdirectory "$HOME/.gemini/$src_dir" "$SCRIPT_DIR/configs/gemini/agents" "Gemini agents"
			break
		fi
	done

	# Copy commands directory (check both 'commands' and 'command' for backward compat)
	for src_dir in commands command; do
		if [ -d "$HOME/.gemini/$src_dir" ]; then
			copy_claude_subdirectory "$HOME/.gemini/$src_dir" "$SCRIPT_DIR/configs/gemini/commands" "Gemini commands"
			break
		fi
	done

	# Copy policies directory
	if [ -d "$HOME/.gemini/policies" ]; then
		copy_claude_subdirectory "$HOME/.gemini/policies" "$SCRIPT_DIR/configs/gemini/policies" "Gemini policies"
	fi

	# Copy skills from ~/.gemini/skills or ~/.agents/skills
	for src_dir in "$HOME/.gemini/skills" "$HOME/.agents/skills"; do
		if [ -d "$src_dir" ]; then
			copy_skills "$src_dir" "$SCRIPT_DIR/configs/gemini/skills" "Gemini CLI"
			# Also sync to central skills/ if needed
			if [ -n "$(ls -A "$src_dir" 2>/dev/null)" ]; then
				log_info "Synchronizing discovered skills to central repository..."
				execute "mkdir -p '$SCRIPT_DIR/skills'"
				execute "cp -rn '$src_dir'/* '$SCRIPT_DIR/skills'/ 2>/dev/null || true"
			fi
		fi
	done

	log_success "Gemini CLI configs generated"
}






generate_best_practices() {
	log_info "Generating best-practices.md..."
	copy_single "$HOME/.ai-tools/best-practices.md" "$SCRIPT_DIR/configs/best-practices.md"
}

generate_memory_md() {
	log_info "Generating MEMORY.md..."

	if [ -f "$HOME/.ai-tools/MEMORY.md" ]; then
		copy_single "$HOME/.ai-tools/MEMORY.md" "$SCRIPT_DIR/MEMORY.md"
	elif [ -f "$SCRIPT_DIR/MEMORY.md" ]; then
		log_success "MEMORY.md already exists in repository (skipping)"
	else
		log_warning "MEMORY.md not found in ~/.ai-tools/ or repository root"
	fi
}


main() {
	echo "╔══════════════════════════════════════════════════════════╗"
	echo "║         Config Generator                                 ║"
	echo "║   Copy user configs TO this repository                   ║"
	echo "╚══════════════════════════════════════════════════════════╝"
	echo

	if [ "$DRY_RUN" = true ]; then
		log_warning "DRY RUN MODE - No changes will be made"
		echo
	fi

	log_info "Generating configs from user directories..."
	echo

	generate_claude_configs
	echo

	generate_opencode_configs
	echo

	echo
	generate_codex_configs
	echo

	generate_gemini_configs
	echo

	generate_best_practices
	echo

	generate_memory_md
	echo

	log_success "Config generation complete!"
	echo
	echo "Review changes with: git diff"
	echo "Commit changes with: git add . && git commit -m 'Update configs'"
}

main
