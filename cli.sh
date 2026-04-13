#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
BACKUP_DIR="$HOME/ai-tools-backup-$(date +%Y%m%d-%H%M%S)"
DRY_RUN=false
BACKUP=false
PROMPT_BACKUP=true
YES_TO_ALL=false
VERBOSE=false
# Installation Flags
INSTALL_CLAUDE=false
INSTALL_GEMINI=false
INSTALL_OPENCODE=false
INSTALL_CODEX=false
INSTALL_HUB=false
INSTALL_BACKENDS=false
INSTALL_TOOLING=false


# Parse command-line arguments
COMMAND=""
declare -a COMMAND_ARGS
while [ $# -gt 0 ]; do
	case $1 in
	--dry-run)
		DRY_RUN=true
		shift
		;;
	--backup)
		BACKUP=true
		PROMPT_BACKUP=false
		shift
		;;
	--no-backup)
		BACKUP=false
		PROMPT_BACKUP=false
		shift
		;;
	--yes | -y)
		YES_TO_ALL=true
		shift
		;;
	-v | --verbose)
		VERBOSE=true
		shift
		;;
	--rollback)
		log_info "Rolling back last transaction..."
		rollback_transaction
		exit $?
		;;
	mcp-hub | mcp_hub)
		COMMAND="mcp-hub"
		shift
		# Collect remaining args for the subcommand
		COMMAND_ARGS=("$@")
		break
		;;
	-*)
		echo "Unknown option: $1"
		echo "Usage: $0 [--dry-run] [--backup] [--no-backup] [--yes|-y] [-v|--verbose] [--rollback] [mcp-hub subcommand]"
		exit 1
		;;
	*)
		# Treat first non-flag as a potential command if not already set
		if [ -z "$COMMAND" ]; then
			COMMAND="$1"
			shift
			COMMAND_ARGS=("$@")
			break
		else
			shift
		fi
		;;
	esac
done

# Auto-detect non-interactive mode AFTER parsing arguments
# This ensures DRY_RUN and other flags are set before any functions use them
if is_non_interactive; then
	YES_TO_ALL=true
	log_info "Non-interactive mode detected (CI or piped input)"
fi
# Interactive component selection
show_selection_menu() {
	if [ "$YES_TO_ALL" = true ]; then
		log_info "Auto-selecting all components (--yes flag)"
		INSTALL_CLAUDE=true
		INSTALL_GEMINI=true
		INSTALL_OPENCODE=true
		INSTALL_CODEX=true
		INSTALL_HUB=true
		INSTALL_BACKENDS=true
		INSTALL_TOOLING=true
		return
	fi

	echo "Select components to install (e.g., 1,2,5 or 'all'):"
	echo "1) Claude Code (CLI)"
	echo "2) Gemini CLI"
	echo "3) OpenCode (TUI/CLI)"
	echo "4) OpenAI Codex CLI"
	echo "5) Shared MCP Hub (V5 Infrastructure)"
	echo "6) Common MCP Backends (fff-mcp, qmd, context7)"
	echo "7) Global Tooling (biome, ruff, jq, etc.)"
	echo "all) Install everything"
	echo
	read -p "Selection: " selection

	if [[ "$selection" == "all" ]]; then
		INSTALL_CLAUDE=true; INSTALL_GEMINI=true; INSTALL_OPENCODE=true;
		INSTALL_CODEX=true; INSTALL_HUB=true; INSTALL_BACKENDS=true; INSTALL_TOOLING=true
		return
	fi

	IFS=',' read -ra ADDR <<< "$selection"
	for i in "${ADDR[@]}"; do
		case $(echo "$i" | xargs) in
			1) INSTALL_CLAUDE=true ;;
			2) INSTALL_GEMINI=true ;;
			3) INSTALL_OPENCODE=true ;;
			4) INSTALL_CODEX=true ;;
			5) INSTALL_HUB=true ;;
			6) INSTALL_BACKENDS=true ;;
			7) INSTALL_TOOLING=true ;;
		esac
	done

	run_setup_wizard
}

# Per-tool configuration wizard
run_setup_wizard() {
	local selected_tools=()
	[ "$INSTALL_CLAUDE" = true ] && selected_tools+=("Claude")
	[ "$INSTALL_GEMINI" = true ] && selected_tools+=("Gemini")
	[ "$INSTALL_OPENCODE" = true ] && selected_tools+=("OpenCode")
	[ "$INSTALL_CODEX" = true ] && selected_tools+=("Codex")

	if [ ${#selected_tools[@]} -eq 0 ]; then
		return
	fi

	echo
	echo "--- Tool Configuration Wizard ---"
	
	local apply_to_all=false
	local shared_mcp_choice="1"
	local shared_skills="all"

	for tool in "${selected_tools[@]}"; do
		echo
		log_info "Configuring $tool:"

		local mcp_choice="1"
		local skill_choice="all"

		if [ "$apply_to_all" = true ]; then
			log_success "Applying shared configuration to $tool"
			mcp_choice="$shared_mcp_choice"
			skill_choice="$shared_skills"
		else
			echo "  Select MCP Connection:"
			echo "    1) Use Shared Hub (Recommended - Connects to local Hub)"
			echo "    2) Standalone (Direct connections, no Hub)"
			read -p "  Choice [1]: " mcp_choice_input
			mcp_choice=${mcp_choice_input:-1}

			echo "  Available Skills in kit:"
			local available_skills=""
			if [ -d "$SCRIPT_DIR/skills" ]; then
				for skill_path in "$SCRIPT_DIR/skills"/*; do
					[ -d "$skill_path" ] && available_skills="$available_skills $(basename "$skill_path"),"
				done
				echo "    [ ${available_skills%,} ]"
			else
				echo "    [ None found in skills/ ]"
			fi
			
			echo "  Select Skills to install by name (e.g. 'pr-review, tdd'), 'all', or 'none':"
			read -p "  Skills [all]: " skill_choice_input
			skill_choice=${skill_choice_input:-all}

			if [ ${#selected_tools[@]} -gt 1 ] && [ "$tool" = "${selected_tools[0]}" ]; then
				echo
				read -p "  Apply this configuration to all other selected tools? (y/N): " apply_choice
				if [[ "$apply_choice" =~ ^[Yy]$ ]]; then
					apply_to_all=true
					shared_mcp_choice="$mcp_choice"
					shared_skills="$skill_choice"
				fi
			fi
		fi

		# Store configuration in standard variables exported for the rest of the script
		export "CONFIG_${tool^^}_MCP"="$mcp_choice"
		export "CONFIG_${tool^^}_SKILLS"="$skill_choice"
	done
}

# Preflight check for required tools
preflight_check() {
	local missing_tools=()

	log_info "Running preflight checks..."

	local required_tools=("awk" "sed" "basename" "cat" "head" "tail" "grep" "date")
	for tool in "${required_tools[@]}"; do
		if ! command -v "$tool" &>/dev/null; then
			missing_tools+=("$tool")
		fi
	done

	if [ ${#missing_tools[@]} -gt 0 ]; then
		log_error "Missing required tools: ${missing_tools[*]}"
		log_info "Please install the missing tools and try again."
		exit 1
	fi

	log_success "All required tools available"
}

# Install MCP server with retry mechanism and better error handling
install_mcp_server() {
	local server_name="$1"
	local install_cmd="$2"
	local max_retries=3
	local retry_count=0
	local backoff=1
	local err_file
	err_file=$(make_temp_file "claude-mcp-${server_name}" "err")

	while [ $retry_count -lt $max_retries ]; do
		# Try installation
		if execute "$install_cmd" 2>"$err_file"; then
			log_success "${server_name} MCP server added (global)"
			rm -f "$err_file"
			return 0
		fi

		# Check if already installed (success case)
		if grep -qi "already" "$err_file" 2>/dev/null; then
			log_info "${server_name} already installed"
			rm -f "$err_file"
			return 0
		fi

		retry_count=$((retry_count + 1))

		# Check if retryable error and we have retries left
		if [ $retry_count -lt $max_retries ] && grep -qiE "(connection|timed?out|network|econnrefused|etimedout)" "$err_file" 2>/dev/null; then
			log_warning "${server_name} installation failed (attempt $retry_count/$max_retries) - retrying in ${backoff}s..."
			sleep "$backoff"
			backoff=$((backoff * 2))
		else
			# Not retryable or out of retries
			break
		fi
	done

	# All retries exhausted or non-retryable error
	log_error "${server_name} installation failed after ${retry_count} attempts"
	if [ -s "$err_file" ]; then
		log_error "Error details:"
		head -20 "$err_file" >&2
	fi
	log_info "You can try installing manually: $install_cmd"
	rm -f "$err_file"
	return 1
}

# Set up TMPDIR to avoid cross-device link errors
setup_tmpdir() {
	local tmp_dir="$HOME/.claude/tmp"
	mkdir -p "$tmp_dir" 2>/dev/null || true
	export TMPDIR="$tmp_dir"
}

check_prerequisites() {
	log_info "Checking prerequisites..."

	if ! command -v git &>/dev/null; then
		log_error "Git is not installed. Please install git first."
		exit 1
	fi
	log_success "Git found"

	if command -v bun &>/dev/null; then
		BUN_VERSION=$(bun --version)
		log_success "Bun found ($BUN_VERSION)"
	elif command -v node &>/dev/null; then
		NODE_VERSION=$(node --version)
		log_success "Node.js found ($NODE_VERSION)"
		handle_optional_bun_installation
	else
		log_error "Neither Bun nor Node.js is installed."
		handle_bun_installation
	fi

	handle_qmd_installation_if_needed
}

handle_optional_bun_installation() {
	if command -v bun &>/dev/null; then
		return 0
	fi

	if [ "$YES_TO_ALL" = true ]; then
		log_info "Auto-installing Bun (--yes flag)..."
		install_bun_now
	elif [ -t 0 ]; then
		if prompt_yn "Bun is not installed. Install it now"; then
			install_bun_now
		else
			log_warning "Continuing with Node.js only. Some scripts prefer Bun."
		fi
	else
		log_warning "Bun is not installed. Continuing with Node.js only."
	fi
}

handle_bun_installation() {
	if [ "$YES_TO_ALL" = true ]; then
		log_info "Auto-installing Bun (--yes flag)..."
		install_bun_now
	elif [ -t 0 ]; then
		if prompt_yn "Would you like to install Bun now"; then
			install_bun_now
		else
			log_error "Please install Bun or Node.js first."
			exit 1
		fi
	else
		log_error "Please install Bun or Node.js first."
		exit 1
	fi
}

handle_qmd_installation_if_needed() {
	if command -v qmd &>/dev/null; then
		local qmd_version
		qmd_version=$(qmd --version 2>/dev/null || echo "version unknown")
		log_success "qmd found ($qmd_version)"
		return 0
	fi

	if [ "$YES_TO_ALL" = true ]; then
		log_info "Auto-installing qmd (--yes flag)..."
		if ! install_qmd_now; then
			log_warning "Continuing without qmd. Knowledge features will remain unavailable until qmd is installed."
		fi
	elif [ -t 0 ]; then
		if prompt_yn "qmd is not installed. Install it now"; then
			if ! install_qmd_now; then
				log_warning "Continuing without qmd. Knowledge features will remain unavailable until qmd is installed."
			fi
		else
			log_warning "qmd not installed. Knowledge features will be unavailable until you install it."
		fi
	else
		log_warning "qmd not installed. Knowledge features will be unavailable until you install it."
	fi
}

install_qmd_now() {
	if command -v qmd &>/dev/null; then
		local qmd_version
		qmd_version=$(qmd --version 2>/dev/null || echo "version unknown")
		log_success "qmd already installed ($qmd_version)"
		return 0
	fi

	if ! command -v bun &>/dev/null; then
		log_info "qmd requires Bun. Installing Bun first..."
		handle_bun_installation
	fi

	if ! command -v bun &>/dev/null; then
		log_error "Cannot install qmd because Bun is still unavailable"
		return 1
	fi

	log_info "Installing qmd CLI via bun..."
	if execute "bun install -g @tobilu/qmd"; then
		# Ensure bun's global bin directory is in PATH for the current session
		local bun_global_bin
		bun_global_bin="$(bun pm bin -g 2>/dev/null)"
		if [ -n "$bun_global_bin" ] && [[ ":$PATH:" != *":$bun_global_bin:"* ]]; then
			export PATH="$bun_global_bin:$PATH"
		fi
		local qmd_version
		qmd_version=$(qmd --version 2>/dev/null || echo "version unknown")
		log_success "qmd installed successfully ($qmd_version)"
		return 0
	fi

	if command -v pnpm &>/dev/null; then
		log_warning "Bun failed to install qmd. Retrying with pnpm..."
		if execute "pnpm install -g @tobilu/qmd"; then
			local qmd_version
			qmd_version=$(qmd --version 2>/dev/null || echo "version unknown")
			log_success "qmd installed successfully ($qmd_version)"
			return 0
		fi
	fi

	log_error "Failed to install qmd"
	return 1
}

install_fff_mcp_now() {
	if command -v fff-mcp &>/dev/null; then
		log_success "fff-mcp already installed"
		return 0
	fi

	log_info "Installing fff-mcp via official installer..."
	if execute_installer "https://dmtrkovalenko.dev/install-fff-mcp.sh" "" "fff-mcp"; then
		# Ensure ~/.local/bin is in PATH for the current session
		local local_bin="$HOME/.local/bin"
		if [[ ":$PATH:" != *":$local_bin:"* ]]; then
			export PATH="$local_bin:$PATH"
		fi
		log_success "fff-mcp installed successfully"
		return 0
	fi

	log_error "Failed to install fff-mcp"
	log_info "You can install it manually: curl -fsSL https://dmtrkovalenko.dev/install-fff-mcp.sh | bash"
	return 1
}

handle_fff_mcp_installation_if_needed() {
	if command -v fff-mcp &>/dev/null; then
		log_success "fff-mcp found"
		return 0
	fi

	if [ "$YES_TO_ALL" = true ]; then
		log_info "Auto-installing fff-mcp (--yes flag)..."
		if ! install_fff_mcp_now; then
			log_warning "Continuing without fff-mcp. Fast file search MCP will be unavailable."
		fi
	elif [ -t 0 ]; then
		if prompt_yn "fff-mcp is not installed. Install it now (fast file search for AI)"; then
			if ! install_fff_mcp_now; then
				log_warning "Continuing without fff-mcp. Fast file search MCP will be unavailable."
			fi
		else
			log_warning "fff-mcp not installed. Fast file search MCP will be unavailable."
		fi
	else
		log_warning "fff-mcp not installed. Fast file search MCP will be unavailable."
	fi
}

resolve_installer_checksum() {
	local installer="$1"
	local checksum_url=""

	case "$installer" in
	bun)
		checksum_url="${BUN_INSTALL_SHA256_URL:-}"
		;;
	rust)
		checksum_url="${RUSTUP_INIT_SHA256_URL:-}"
		;;
	plannotator)
		checksum_url="${PLANNOTATOR_INSTALL_SHA256_URL:-}"
		;;
	esac

	if [ -z "$checksum_url" ]; then
		log_warning "No checksum URL configured for ${installer} installer"
		echo ""
		return 0
	fi

	local checksum
	checksum=$(curl -fsSL "$checksum_url" 2>/dev/null | head -n1 | awk '{print $1}')

	if [ -z "$checksum" ]; then
		log_warning "Could not fetch checksum for ${installer} installer"
	fi

	echo "$checksum"
}

install_bun_now() {
	log_info "Installing Bun..."

	local bun_checksum
	bun_checksum=$(resolve_installer_checksum "bun")
	if execute_installer "https://bun.sh/install" "$bun_checksum" "Bun"; then
		# Source shell profiles to get Bun environment
		[ -f "$HOME/.bashrc" ] && source "$HOME/.bashrc" 2>/dev/null || true
		[ -f "$HOME/.zshrc" ] && source "$HOME/.zshrc" 2>/dev/null || true

		# Fallback to default Bun location
		if [ -z "$BUN_INSTALL" ]; then
			export BUN_INSTALL="$HOME/.bun"
		fi
		export PATH="$BUN_INSTALL/bin:$PATH"

		if command -v bun &>/dev/null; then
			BUN_VERSION=$(bun --version)
			log_success "Bun installed successfully ($BUN_VERSION)"
		else
			log_error "Bun installation completed but 'bun' command not found in PATH"
			exit 1
		fi
	else
		log_error "Failed to install Bun"
		exit 1
	fi
}

install_global_tools() {
	log_info "Checking global tools for PostToolUse hooks..."

	install_jq_if_needed
	install_biome_if_needed
	check_gofmt
	install_ruff_if_needed
	install_rustfmt_if_needed
	install_shfmt_if_needed
	install_stylua_if_needed

	log_success "Global tools check complete"
}

install_jq_if_needed() {
	if command -v jq &>/dev/null; then
		log_success "jq found"
		return 0
	fi

	log_warning "jq not found. Installing jq..."
	local jq_installed=false

	if [ "$IS_WINDOWS" = true ]; then
		if command -v choco &>/dev/null; then
			execute "choco install jq -y" && jq_installed=true
		elif command -v winget &>/dev/null; then
			# Use correct package ID with exact match flag
			execute "winget install -e --id jqlang.jq --accept-package-agreements --accept-source-agreements" && jq_installed=true
		fi

		# After winget install, refresh PATH in current session
		if [ "$jq_installed" = true ]; then
			# winget adds to PATH but current shell doesn't know about it
			# Try common jq installation locations
			local jq_path=""
			if [ -f "$LOCALAPPDATA/Microsoft/WinGet/Packages/jqlang.jq_Microsoft.Winget.Source_8wekyb3d8bbwe/jq.exe" ]; then
				jq_path="$LOCALAPPDATA/Microsoft/WinGet/Packages/jqlang.jq_Microsoft.Winget.Source_8wekyb3d8bbwe"
			elif [ -f "$PROGRAMFILES/jq/jq.exe" ]; then
				jq_path="$PROGRAMFILES/jq"
			elif [ -f "$PROGRAMFILES/WinGet/Links/jq.exe" ]; then
				jq_path="$PROGRAMFILES/WinGet/Links"
			fi

			if [ -n "$jq_path" ]; then
				export PATH="$jq_path:$PATH"
				log_info "Added jq to PATH: $jq_path"
			fi

			# Verify jq is now available
			if ! command -v jq &>/dev/null; then
				log_warning "jq installed but not found in PATH. Please restart your terminal."
				jq_installed=false
			fi
		fi
	else
		if command -v brew &>/dev/null; then
			execute "brew install jq" && jq_installed=true
		elif command -v apt-get &>/dev/null; then
			if ([ "$YES_TO_ALL" = true ] && sudo -n true 2>/dev/null) || ([ "$YES_TO_ALL" = false ] && [ -t 0 ]); then
				execute "sudo apt-get install -y jq" && jq_installed=true
			else
				log_warning "Cannot install jq non-interactively (requires sudo with password)"
			fi
		fi
	fi

	if [ "$jq_installed" = false ]; then
		log_warning "Please install jq manually: https://jqlang.github.io/jq/download/"
		if [ "$IS_WINDOWS" = true ]; then
			log_info "Windows installation options:"
			log_info "  - winget: winget install -e --id jqlang.jq"
			log_info "  - chocolatey: choco install jq"
			log_info "  - Scoop: scoop install jq"
			log_info "  - GitHub: https://github.com/jqlang/jq/releases"
		fi
	fi
}

install_biome_if_needed() {
	if command -v biome &>/dev/null; then
		log_success "biome found"
		return 0
	fi

	log_warning "biome not found. Installing biome globally..."
	if execute "pnpm install -g @biomejs/biome"; then
		log_success "biome installed"
	else
		log_warning "Failed to install biome"
	fi
}

check_gofmt() {
	if command -v gofmt &>/dev/null; then
		log_success "gofmt found"
		return 0
	fi

	log_warning "gofmt not found. Go is not installed."
	if [ "$IS_WINDOWS" = true ]; then
		if command -v choco &>/dev/null; then
			log_info "Install Go with: choco install golang -y"
		elif command -v winget &>/dev/null; then
			log_info "Install Go with: winget install GoLang.Go"
		else
			log_info "Please install Go manually: https://golang.org/dl/"
		fi
	else
		if command -v brew &>/dev/null; then
			log_info "Install Go with: brew install go"
		elif command -v apt-get &>/dev/null; then
			log_info "Install Go with: sudo apt-get install -y golang"
		else
			log_info "Please install Go manually: https://golang.org/dl/"
		fi
	fi
}

install_ruff_if_needed() {
	if command -v ruff &>/dev/null; then
		log_success "ruff found"
		return 0
	fi

	log_warning "ruff not found. Installing ruff..."
	if command -v mise &>/dev/null; then
		execute "mise use -g ruff@latest"
	elif command -v pipx &>/dev/null; then
		execute "pipx install ruff"
	elif command -v pip3 &>/dev/null; then
		execute "pip3 install ruff"
	elif command -v pip &>/dev/null; then
		execute "pip install ruff"
	else
		log_warning "No Python package manager found. Install ruff manually: https://docs.astral.sh/ruff/installation/"
	fi
}

install_rustfmt_if_needed() {
	if command -v rustfmt &>/dev/null; then
		log_success "rustfmt found"
		return 0
	fi

	log_warning "rustfmt not found. Installing Rust..."
	if command -v mise &>/dev/null; then
		execute "mise use -g rust@latest"
	elif command -v brew &>/dev/null; then
		execute "brew install rust"
	else
		local rust_checksum
		rust_checksum=$(resolve_installer_checksum "rust")
		execute_installer "https://sh.rustup.rs" "$rust_checksum" "Rust" "-y"
	fi
}

install_shfmt_if_needed() {
	if command -v shfmt &>/dev/null; then
		log_success "shfmt found"
		return 0
	fi

	log_warning "shfmt not found. Installing shfmt..."
	if command -v mise &>/dev/null; then
		execute "mise use -g shfmt@latest"
	elif command -v brew &>/dev/null; then
		execute "brew install shfmt"
	elif command -v go &>/dev/null; then
		execute "go install mvdan.cc/sh/v3/cmd/shfmt@latest"
	else
		log_warning "No package manager found for shfmt. Install manually: https://github.com/mvdan/sh"
	fi
}

install_stylua_if_needed() {
	if command -v stylua &>/dev/null; then
		log_success "stylua found"
		return 0
	fi

	log_warning "stylua not found. Installing stylua..."
	if command -v mise &>/dev/null; then
		execute "mise use -g stylua@latest"
	elif command -v brew &>/dev/null; then
		execute "brew install stylua"
	elif command -v cargo &>/dev/null; then
		execute "cargo install stylua"
	else
		log_warning "No package manager found for stylua. Install manually: https://github.com/JohnnyMorganz/StyLua"
	fi
}

# Helper: Safely copy a directory, handling "Text file busy" errors
# Usage: safe_copy_dir "source_dir" "dest_dir"
safe_copy_dir() {
	local source_dir="$1"
	local dest_dir="$2"
	local skipped=0
	local errors=0

	if [ "$DRY_RUN" = true ]; then
		log_info "[DRY RUN] Would copy $source_dir to $dest_dir"
		return 0
	fi

	if ! mkdir -p "$(dirname "$dest_dir")" 2>/dev/null; then
		log_warning "Failed to create destination directory: $(dirname "$dest_dir")"
		return 1
	fi

	# Directories to exclude from copies
	local -a exclude_dirs=(
		"node_modules" "plugins" "projects" "debug" "sessions" "git"
		"cache" "extensions" "chats" "antigravity" "antigravity-browser-profile"
		"log" "logs" "tmp" "vendor_imports" "file-history" "ai-tracking"
	)

	# Prefer rsync when available
	if command -v rsync &>/dev/null; then
		local -a rsync_excludes=()
		for dir in "${exclude_dirs[@]}"; do
			rsync_excludes+=(--exclude "$dir" --exclude "$dir/**")
		done
		rsync_excludes+=(--exclude "*.sqlite" --exclude "*.sqlite-wal" --exclude "*.sqlite-shm")
		if rsync -a --ignore-errors "${rsync_excludes[@]}" "$source_dir/" "$dest_dir/" 2>/dev/null; then
			return 0
		fi
	fi

	# Fallback: manual copy
	local prune_expr=""
	for dir in "${exclude_dirs[@]}"; do
		prune_expr="$prune_expr -name $dir -o"
	done
	prune_expr="${prune_expr% -o}"

	mkdir -p "$dest_dir"
	while IFS= read -r file; do
		case "$file" in *.sqlite | *.sqlite-wal | *.sqlite-shm) continue ;; esac
		local rel_path="${file#"$source_dir"/}"
		local dest_file="$dest_dir/$rel_path"
		mkdir -p "$(dirname "$dest_file")"
		if ! cp "$file" "$dest_file" 2>/dev/null; then
			((errors++))
			((skipped++))
			[ "$VERBOSE" = true ] && log_warning "Skipped busy file: $rel_path"
		fi
	done < <(find "$source_dir" -type d \( $prune_expr \) -prune -o -type f -print 2>/dev/null)

	[ "$VERBOSE" = true ] && [ $skipped -gt 0 ] && log_info "Skipped $skipped busy file(s)"
	return 0
}

# Helper: Copy a config directory if it exists in source and destination
# Usage: copy_config_dir "source_dir" "dest_parent" "dest_name"
copy_config_dir() {
	local source_dir="$1"
	local dest_parent="$2"
	local dest_name="$3"

	if [ -d "$source_dir" ]; then
		execute_quoted mkdir -p "$dest_parent"
		safe_copy_dir "$source_dir" "$dest_parent/$dest_name"
		log_success "Backed up $dest_name configs"
	fi
}

# Helper: Copy a config file if it exists in source
# Usage: copy_config_file "source_file" "dest_dir"
copy_config_file() {
	local source_file="$1"
	local dest_dir="$2"

	if [ -f "$source_file" ]; then
		execute_quoted mkdir -p "$dest_dir"
		execute_quoted cp "$source_file" "$dest_dir/"
		return 0
	fi
	return 1
}

# Helper: Ensure a CLI tool is installed, prompting if interactive
# Usage: ensure_cli_tool "tool_name" "install_cmd" "version_cmd"
ensure_cli_tool() {
	local name="$1"
	local install_cmd="$2"
	local version_cmd="${3:-}"

	if command -v "$name" &>/dev/null; then
		if [ -n "$version_cmd" ]; then
			local version
			version=$($version_cmd 2>/dev/null)
			log_success "$name found ($version)"
		else
			log_success "$name found"
		fi
		return 0
	fi

	log_warning "$name not found. Installing..."
	$install_cmd
}

backup_configs() {
	cleanup_old_backups 5

	if [ "$PROMPT_BACKUP" = true ]; then
		if [ "$YES_TO_ALL" = true ]; then
			log_info "Auto-accepting backup (--yes flag)"
			BACKUP=true
		elif [ -t 0 ]; then
			if prompt_yn "Do you want to backup existing configurations"; then
				BACKUP=true
			fi
		else
			log_info "Skipping backup prompt in non-interactive mode (use --backup to force backup)"
		fi
	fi

	if [ "$BACKUP" = true ]; then
		log_info "Creating backup at $BACKUP_DIR..."
		execute_quoted mkdir -p "$BACKUP_DIR"

		copy_config_dir "$HOME/.claude" "$BACKUP_DIR" "claude"
		copy_config_dir "$HOME/.config/opencode" "$BACKUP_DIR" "opencode"
		copy_config_dir "$HOME/.codex" "$BACKUP_DIR" "codex"
		copy_config_dir "$HOME/.gemini" "$BACKUP_DIR" "gemini"

		log_success "Backup completed: $BACKUP_DIR"
	fi
}

install_claude_code() {
	log_info "Installing Claude Code..."

	if ! command -v claude &>/dev/null; then
		if execute "pnpm install -g @anthropic-ai/claude-code"; then
			log_success "Claude Code installed"
		else
			log_error "Failed to install Claude Code"
		fi
		return
	fi

	log_warning "Claude Code is already installed ($(claude --version))"

	if [ "$YES_TO_ALL" = true ]; then
		log_info "Auto-skipping reinstall (--yes flag)"
		return
	elif [ -t 0 ]; then
		if ! prompt_yn "Do you want to reinstall"; then
			return
		fi
	else
		log_info "Skipping reinstall in non-interactive mode"
		return
	fi

	if execute "pnpm install -g @anthropic-ai/claude-code"; then
		log_success "Claude Code reinstalled"
	else
		log_error "Failed to reinstall Claude Code"
	fi
}

install_opencode() {
	_run_opencode_install() {
		if command -v opencode &>/dev/null; then
			log_warning "OpenCode is already installed"
		else
			execute_installer "https://opencode.ai/install" "" "OpenCode"
			log_success "OpenCode installed"
		fi
	}
	run_installer "OpenCode" "_run_opencode_install" "command -v opencode" ""
}




install_codex() {
	_run_codex_install() {
		if command -v codex &>/dev/null; then
			log_warning "Codex CLI is already installed"
		else
			execute "pnpm install -g @openai/codex"
			log_success "Codex CLI installed"
		fi
	}
	run_installer "OpenAI Codex CLI" "_run_codex_install" "command -v codex" ""
}

install_gemini() {
	_run_gemini_install() {
		if command -v gemini &>/dev/null; then
			log_warning "Gemini CLI is already installed"
		else
			execute "pnpm install -g @google/gemini-cli"
			log_success "Gemini CLI installed"
		fi
	}
	run_installer "Google Gemini CLI" "_run_gemini_install" "command -v gemini" ""
}

# --- Shared MCP Multiplexer ---

install_shared_mcp() {
	log_info "Setting up Shared MCP Multiplexer globally..."
	local source_hub_dir="$SCRIPT_DIR/configs/shared-mcp"
	local target_hub_dir="$HOME/.ai-tools/shared-mcp"
	
	if [ ! -d "$source_hub_dir" ]; then
		log_error "Shared MCP source directory not found at $source_hub_dir"
		return 1
	fi

	execute_quoted mkdir -p "$target_hub_dir"
	safe_copy_dir "$source_hub_dir" "$target_hub_dir"

	if [ "$DRY_RUN" = true ]; then
		log_info "[DRY RUN] (cd $target_hub_dir && bun install)"
	else
		(cd "$target_hub_dir" && execute "bun install")
	fi
	log_success "Shared MCP installed to $target_hub_dir"

}

ensure_hub_running() {
	local pid_file="/tmp/shared-mcp-hub.pid"
	if [ -f "$pid_file" ] && kill -0 $(cat "$pid_file") 2>/dev/null; then
		# Hub is running, check if it responds
		if curl -s http://localhost:5115/status >/dev/null 2>&1; then
			return 0
		fi
	fi
	
	log_info "Shared MCP Hub not active - performing lazy auto-start..."
	mcp_hub start
}

mcp_hub() {
	mcp-hub "$@"
}

mcp-hub() {
	local action="$1"
	local hub_dir="$HOME/.ai-tools/shared-mcp"
	local pid_file="$hub_dir/hub.pid"
	local log_file="$hub_dir/hub.log"
	
	case "$action" in
		start)
			if [ -f "$pid_file" ] && kill -0 $(cat "$pid_file") 2>/dev/null; then
				log_warning "Shared MCP Hub is already running (PID: $(cat "$pid_file"))"
				return 0
			fi
			if lsof -i :5115 >/dev/null 2>&1; then
				log_warning "Port 5115 is already in use. Attempting to clear..."
				fuser -k 5115/tcp 2>/dev/null || true
				sleep 1
			fi

			log_info "Starting Shared MCP Hub V5..."
			if [ "$DRY_RUN" = true ]; then
				log_info "[DRY RUN] (cd $hub_dir && nohup bun run multiplexer.ts > $log_file 2>&1 & echo \$! > $pid_file)"
				return 0
			fi
			# Ensure common paths are available to the Hub
			local hub_path="$PATH"
			[[ ":$hub_path:" != *":$HOME/.local/bin:"* ]] && hub_path="$HOME/.local/bin:$hub_path"
			local bun_bin; bun_bin=$(bun pm bin -g 2>/dev/null)
			[[ -n "$bun_bin" && ":$hub_path:" != *":$bun_bin:"* ]] && hub_path="$bun_bin:$hub_path"

			(cd "$hub_dir" && export PATH="$hub_path" && nohup bun run multiplexer.ts > "$log_file" 2>&1 & echo $! > "$pid_file")
			
			local count=0
			local max_retries=15
			while [ $count -lt $max_retries ]; do
				if curl -s http://localhost:5115/status >/dev/null 2>&1; then
					log_success "Shared MCP Hub V5 ACTIVE on http://localhost:5115"
					return 0
				fi
				sleep 1
				count=$((count+1))
			done
			log_error "Failed to start. Check $log_file"
			echo "--- Last 5 lines of $log_file ---"
			tail -n 5 "$log_file"
			rm -f "$pid_file"
			return 1
			;;
		compose-setup)
			log_info "Setting up Podman Compose deployment..."
			# Cleanup legacy Kube files if they exist
			rm -f "$SCRIPT_DIR/configs/shared-mcp/hub-pod.yaml"
			rm -f "$HOME/.config/systemd/user/shared-mcp-pod.service"
			
			log_success "Podman Compose environment ready at $SCRIPT_DIR/configs/shared-mcp/docker-compose.yml"
			log_info "You can now run './cli.sh mcp-hub service-install' or 'podman-compose up -d'"
			;;
		service-install)
			log_info "Installing Systemd user service for Shared MCP Hub (Compose)..."
			mkdir -p "$HOME/.config/systemd/user"
			local unit_src="$SCRIPT_DIR/configs/shared-mcp/shared-mcp.service"
			local unit_dest="$HOME/.config/systemd/user/shared-mcp.service"
			
			# Substitute variables in unit file
			sed "s|\$REPLACE_WITH_PROJECT_DIR|$SCRIPT_DIR|g" "$unit_src" > "$unit_dest"
			
			systemctl --user daemon-reload
			systemctl --user enable shared-mcp.service
			log_success "Systemd service installed and enabled at $unit_dest"
			log_info "Use 'systemctl --user start shared-mcp' to launch"
			;;
		compose-up)
			log_info "Launching Hub via Podman Compose..."
			(cd "$SCRIPT_DIR/configs/shared-mcp" && export PROJECT_DIR="$SCRIPT_DIR" && podman compose up -d)
			log_success "Podman Compose deployment active"
			;;
		compose-down)
			log_info "Stopping Podman Compose deployment..."
			(cd "$SCRIPT_DIR/configs/shared-mcp" && podman compose down)
			log_success "Podman Compose deployment stopped"
			;;
		cleanup-legacy)
			log_info "Cleaning up legacy (non-containerized) Hub artifacts..."
			# 1. Kill any stale local processes
			if [ -f "$HOME/.ai-tools/shared-mcp/hub.pid" ]; then
				local pid=$(cat "$HOME/.ai-tools/shared-mcp/hub.pid")
				kill "$pid" 2>/dev/null || true
				rm -f "$HOME/.ai-tools/shared-mcp/hub.pid"
			fi
			fuser -k 5115/tcp 2>/dev/null || true
			
			# 2. Remove legacy systemd units
			rm -f "$HOME/.config/systemd/user/shared-mcp-pod.service"
			systemctl --user daemon-reload
			
			# 3. Clean up old logs
			rm -f "$HOME/.ai-tools/shared-mcp/hub.log"
			
			log_success "Legacy cleanup complete. Only Podman services remain."
			;;
		podman-setup | podman-start | podman-stop)
			log_error "Deprecated command. Please use 'mcp-hub compose-setup' or 'mcp-hub service-install'"
			exit 1
			;;
		stop)
			if [ -f "$pid_file" ]; then
				local pid=$(cat "$pid_file")
				log_info "Stopping Shared MCP Hub (PID: $pid)..."
				kill "$pid" 2>/dev/null || true
				rm -f "$pid_file"
				log_success "Hub stopped"
			else
				log_warning "Hub is not running"
			fi
			;;
		status)
			if [ -f "$pid_file" ] && kill -0 $(cat "$pid_file") 2>/dev/null; then
				local pid=$(cat "$pid_file")
				log_success "Hub Process ACTIVE (PID: $pid)"
				echo "--- Health Dashboard ---"
				curl -s http://localhost:5115/status | jq .
			else
				log_warning "Shared MCP Hub is INACTIVE"
			fi
			;;
		*)
			echo "Usage: $0 mcp_hub {start|stop|status}"
			;;
	esac
}













# Helper: Copy skills from source to destination
# Usage: copy_skills "source_dir" "dest_dir"
copy_skills() {
	local source_dir="$1"
	local dest_dir="$2"

	if [ ! -d "$source_dir" ] || [ -z "$(ls -A "$source_dir" 2>/dev/null)" ]; then
		return 0
	fi

	# Check if global skills directory exists - if so, skip copying to tool-specific dirs
	# to avoid conflicts. Global ~/.agents/skills/ is the preferred location.
	if [ -d "$HOME/.agents/skills" ] && [ "$YES_TO_ALL" = true ]; then
		log_info "Global skills directory found at ~/.agents/skills - skipping tool-specific skill copy to avoid conflicts"
		return 0
	fi

	execute_quoted rm -rf "$dest_dir"
	execute_quoted mkdir -p "$dest_dir"

	for skill_dir in "$source_dir"/*; do
		if [ ! -d "$skill_dir" ]; then
			continue
		fi

		case "$skill_name" in
		prd | ralph | qmd-knowledge | codemap | adr | handoffs | pickup | pr-review | slop | tdd | grill-me | plannotator-compound | plannotator-review)
			# Skip skills that conflict with ~/.agents/skills/
			;;
		*)
			safe_copy_dir "$skill_dir" "$dest_dir/$skill_name"
			;;
		esac
	done
}

# Helper: Copy OpenCode commands, skipping my-ai-tools folder
# Usage: copy_opencode_commands "source_dir" "dest_dir"
copy_opencode_commands() {
	local source_dir="$1"
	local dest_dir="$2"

	if [ ! -d "$source_dir" ] || [ -z "$(ls -A "$source_dir" 2>/dev/null)" ]; then
		return 0
	fi

	execute_quoted mkdir -p "$dest_dir"

	for item in "$source_dir"/*; do
		if [ -d "$item" ]; then
			local command_name
			command_name="$(basename "$item")"
			[ "$command_name" = "my-ai-tools" ] && continue
			safe_copy_dir "$item" "$dest_dir/$command_name"
		elif [ -f "$item" ]; then
			execute_quoted cp "$item" "$dest_dir/"
		fi
	done
}

# Helper: Install MCP server with interactive prompts
# Usage: install_mcp_interactive "name" "install_cmd" "description"
install_mcp_interactive() {
	local name="$1"
	local install_cmd="$2"
	local description="$3"

	if [ "$YES_TO_ALL" = true ]; then
		log_info "Auto-accepting MCP server installation (--yes flag)"
		if execute "$install_cmd"; then
			log_success "$name MCP server added (global)"
		else
			log_warning "$name already installed or failed"
		fi
	elif [ -t 0 ]; then
		if prompt_yn "Install $name MCP server ($description)"; then
			if execute "$install_cmd"; then
				log_success "$name MCP server added (global)"
			else
				log_warning "$name already installed or failed"
			fi
		fi
	else
		install_mcp_server "$name" "$install_cmd"
	fi
}

copy_configurations() {
	log_info "Copying configurations..."

	validate_all_configs

	[ "$INSTALL_CLAUDE" = true ] && copy_claude_configs
	[ "$INSTALL_OPENCODE" = true ] && copy_opencode_configs
	[ "$INSTALL_CODEX" = true ] && copy_codex_configs
	[ "$INSTALL_GEMINI" = true ] && copy_gemini_configs
	copy_best_practices
}

# Validate all config files
validate_all_configs() {
	log_info "Validating configuration files..."
	local config_validation_failed=false

	# Validate Claude Code configs
	if ! validate_config_with_schema "$SCRIPT_DIR/configs/claude/claude.json"; then
		log_error "Claude Code claude.json failed validation"
		config_validation_failed=true
	fi

	# Validate OpenCode config
	if [ -f "$SCRIPT_DIR/configs/opencode/opencode.json" ]; then
		if ! validate_config_with_schema "$SCRIPT_DIR/configs/opencode/opencode.json"; then
			log_error "OpenCode config failed validation"
			config_validation_failed=true
		fi
	fi
	if [ -f "$SCRIPT_DIR/configs/opencode/tui.json" ]; then
		if ! validate_config_with_schema "$SCRIPT_DIR/configs/opencode/tui.json"; then
			log_error "OpenCode TUI config failed validation"
			config_validation_failed=true
		fi
	fi

	# Validate other tool configs
	for config_file in "$SCRIPT_DIR/configs/codex/config.json" \
		"$SCRIPT_DIR/configs/gemini/settings.json"; do
		if [ -f "$config_file" ] && ! validate_config "$config_file"; then
			log_error "Config validation failed: $config_file"
			config_validation_failed=true
		fi
	done

	if [ "$config_validation_failed" = true ]; then
		log_warning "Some configuration files failed validation"
		if [ "$YES_TO_ALL" = false ] && [ -t 0 ]; then
			if ! prompt_yn "Continue anyway"; then
				log_error "Installation aborted due to config validation failures"
				exit 1
			fi
		else
			log_info "Continuing despite validation failures (--yes or non-interactive mode)"
		fi
	else
		log_success "All configuration files validated successfully"
	fi
}

copy_claude_configs() {
	execute_quoted mkdir -p "$HOME/.claude"

	# Copy core configs
	execute_quoted cp "$SCRIPT_DIR/configs/claude/claude.json" "$HOME/.claude/claude.json"
	execute_quoted cp "$SCRIPT_DIR/configs/claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"

	# Copy directories
	execute_quoted rm -rf "$HOME/.claude/commands"
	safe_copy_dir "$SCRIPT_DIR/configs/claude/commands" "$HOME/.claude/commands"

	if [ -d "$SCRIPT_DIR/configs/claude/agents" ]; then
		safe_copy_dir "$SCRIPT_DIR/configs/claude/agents" "$HOME/.claude/agents"
	fi

	if [ -d "$SCRIPT_DIR/configs/claude/hooks" ]; then
		execute_quoted mkdir -p "$HOME/.claude/hooks"
		safe_copy_dir "$SCRIPT_DIR/configs/claude/hooks" "$HOME/.claude/hooks"
		log_success "Claude Code hooks installed"
	fi

	# Add MCP servers
	setup_claude_mcp_servers

	log_success "Claude Code configs copied"
}

setup_claude_mcp_servers() {
	if ! command -v claude &>/dev/null; then
		return 0
	fi

	log_info "Setting up Claude Code MCP..."
	
	if [ "$CONFIG_CLAUDE_MCP" = "1" ] || [[ -z "$CONFIG_CLAUDE_MCP" && "$INSTALL_HUB" = true ]]; then
		log_info "Linking Shared Hub Bridge to Claude..."
		local bridge_path="$HOME/.ai-tools/shared-mcp/bridge.ts"
		
		# Check if already exists before adding
		if ! claude mcp list --scope user 2>/dev/null | grep -q "shared-hub"; then
			execute "claude mcp add --scope user --transport stdio shared-hub -- bun run $bridge_path"
			log_success "Claude now connected via Shared Hub Bridge"
		else
			log_info "Claude Shared Hub already exists - skipping registration"
		fi
	elif [ "$CONFIG_CLAUDE_MCP" = "2" ]; then
		log_info "Setting up standalone MCP servers for Claude..."
		install_mcp_interactive "context7" "claude mcp add --scope user --transport stdio context7 -- npx -y @upstash/context7-mcp@latest" "documentation lookup"
		install_mcp_interactive "sequential-thinking" "claude mcp add --scope user --transport stdio sequential-thinking -- npx -y @modelcontextprotocol/server-sequential-thinking" "multi-step reasoning"
	fi
}


setup_backend_services() {
	if [ "$INSTALL_BACKENDS" != true ]; then
		return 0
	fi

	log_info "Installing common MCP backend services..."
	handle_qmd_installation_if_needed
	handle_fff_mcp_installation_if_needed
	
	log_success "Backend services available for Hub usage"
}



copy_opencode_configs() {
	local opencode_status
	opencode_status=$(detect_tool --detailed "opencode" "$HOME/.config/opencode") || opencode_status="missing"
	if [ "$opencode_status" = "missing" ]; then
		log_info "OpenCode not detected - skipping OpenCode config installation"
		return 0
	fi

	log_info "Detected OpenCode (via $opencode_status)"
	execute_quoted mkdir -p "$HOME/.config/opencode"
	execute_quoted cp "$SCRIPT_DIR/configs/opencode/opencode.json" "$HOME/.config/opencode/"

	if [ -f "$SCRIPT_DIR/configs/opencode/tui.json" ]; then
		execute_quoted cp "$SCRIPT_DIR/configs/opencode/tui.json" "$HOME/.config/opencode/"
	fi

	execute_quoted rm -rf "$HOME/.config/opencode/agents"
	safe_copy_dir "$SCRIPT_DIR/configs/opencode/agents" "$HOME/.config/opencode/agents"

	execute_quoted rm -rf "$HOME/.config/opencode/commands"
	copy_opencode_commands "$SCRIPT_DIR/configs/opencode/commands" "$HOME/.config/opencode/commands"

	if [ -d "$SCRIPT_DIR/configs/opencode/skills" ]; then
		execute_quoted rm -rf "$HOME/.config/opencode/skills"
		safe_copy_dir "$SCRIPT_DIR/configs/opencode/skills" "$HOME/.config/opencode/skills"
	fi

	log_success "OpenCode configs copied"
}

copy_codex_configs() {
	local codex_status
	codex_status=$(detect_tool --detailed "codex" "$HOME/.codex") || codex_status="missing"
	if [ "$codex_status" = "missing" ]; then
		log_info "Codex CLI not detected - skipping Codex config installation"
		return 0
	fi

	log_info "Detected Codex CLI (via $codex_status)"
	execute_quoted mkdir -p "$HOME/.codex"

	copy_config_file "$SCRIPT_DIR/configs/codex/AGENTS.md" "$HOME/.codex/" || true

	if [ -f "$SCRIPT_DIR/configs/codex/config.toml" ]; then
		if [ -f "$HOME/.codex/config.toml" ]; then
			execute_quoted cp "$HOME/.codex/config.toml" "$HOME/.codex/config.toml.bak"
			log_success "Backed up existing config.toml to config.toml.bak"
		fi
		execute_quoted cp "$SCRIPT_DIR/configs/codex/config.toml" "$HOME/.codex/"
		
		# If user selected Shared Hub, forcefully rewrite the MCP configuration dynamically.
		if [ "$CONFIG_CODEX_MCP" = "1" ] || [[ -z "$CONFIG_CODEX_MCP" && "$INSTALL_HUB" = true ]]; then
			log_info "Configuring Codex to use Shared Hub..."
			# Using shell execution to strip existing [mcp_servers.*] blocks
			if [ "$DRY_RUN" = true ]; then
				log_info "[DRY RUN] Would rewrite $HOME/.codex/config.toml to remove standalone servers and inject shared-hub"
			else
				awk '
				/^\[mcp_servers\./ {skip=1; next}
				/^\[/ && !/^\[mcp_servers\./ {skip=0}
				!skip {print}
				' "$HOME/.codex/config.toml" > "$HOME/.codex/config.toml.tmp"
				
				# Inject the dynamically computed project bridge path
				cat <<EOF >> "$HOME/.codex/config.toml.tmp"

[mcp_servers.shared-hub]
command = "bun"
args = ["run", "$HOME/.ai-tools/shared-mcp/bridge.ts"]
EOF
				mv "$HOME/.codex/config.toml.tmp" "$HOME/.codex/config.toml"
			fi
			log_success "Codex MCP configured for Shared Hub"
		fi
	fi

	if [ -d "$SCRIPT_DIR/configs/codex/themes" ]; then
		execute_quoted mkdir -p "$HOME/.codex/themes"
		safe_copy_dir "$SCRIPT_DIR/configs/codex/themes" "$HOME/.codex/themes"
	fi

	log_success "Codex CLI configs copied"
}

copy_gemini_configs() {
	local gemini_status
	gemini_status=$(detect_tool --detailed "gemini" "$HOME/.gemini") || gemini_status="missing"
	if [ "$gemini_status" = "missing" ]; then
		log_info "Gemini CLI not detected - skipping Gemini config installation"
		return 0
	fi

	log_info "Detected Gemini CLI (via $gemini_status)"
	execute_quoted mkdir -p "$HOME/.gemini"

	copy_config_file "$SCRIPT_DIR/configs/gemini/AGENTS.md" "$HOME/.gemini/" || true
	copy_config_file "$SCRIPT_DIR/configs/gemini/GEMINI.md" "$HOME/.gemini/" || true
	copy_config_file "$SCRIPT_DIR/configs/gemini/settings.json" "$HOME/.gemini/" || true

	execute_quoted rm -rf "$HOME/.gemini/agents"
	safe_copy_dir "$SCRIPT_DIR/configs/gemini/agents" "$HOME/.gemini/agents"

	execute_quoted rm -rf "$HOME/.gemini/commands"
	safe_copy_dir "$SCRIPT_DIR/configs/gemini/commands" "$HOME/.gemini/commands"

	execute_quoted rm -rf "$HOME/.gemini/policies"
	execute_quoted mkdir -p "$HOME/.gemini/policies"
	safe_copy_dir "$SCRIPT_DIR/configs/gemini/policies" "$HOME/.gemini/policies"

	log_success "Gemini CLI configs copied"
}

copy_best_practices() {
	execute_quoted mkdir -p "$HOME/.ai-tools"
	execute_quoted cp "$SCRIPT_DIR/configs/best-practices.md" "$HOME/.ai-tools/"
	log_success "Best practices copied to ~/.ai-tools/"
	execute_quoted cp "$SCRIPT_DIR/configs/git-guidelines.md" "$HOME/.ai-tools/"
	log_success "Git guidelines copied to ~/.ai-tools/"

	if [ -f "$SCRIPT_DIR/MEMORY.md" ]; then
		execute_quoted cp "$SCRIPT_DIR/MEMORY.md" "$HOME/.ai-tools/"
		log_success "MEMORY.md copied to ~/.ai-tools/"
	fi
}



# Helper: Install remote skills using npx skills add
install_remote_skills() {
	log_info "Installing community skills from jellydn/my-ai-tools repository..."

	if ! command -v npx &>/dev/null; then
		log_error "npx not found. Please install Node.js to use remote skill installation."
		install_local_skills
		return 0
	fi

	if [ "${YES_TO_ALL:-false}" = "true" ] || [ ! -t 0 ]; then
		execute "npx skills add jellydn/my-ai-tools --yes --global --agent claude-code"
	else
		execute "npx skills add jellydn/my-ai-tools --global --agent claude-code"
	fi
	log_success "Remote skills installed successfully"
}

# Helper: Install recommended community skills from recommend-skills.json
install_recommended_skills() {
	log_info "Checking for recommended community skills..."

	if ! command -v npx &>/dev/null; then
		log_warning "npx not found, skipping recommended skills"
		return 0
	fi

	if [ ! -f "$SCRIPT_DIR/configs/recommend-skills.json" ]; then
		log_info "No recommended skills config found, skipping"
		return 0
	fi

	local skills_json
	skills_json=$(cat "$SCRIPT_DIR/configs/recommend-skills.json")
	local skill_count
	skill_count=$(echo "$skills_json" | jq '.recommended_skills | length')

	if [ "$skill_count" -eq 0 ] || [ "$skill_count" = "null" ]; then
		log_info "No recommended skills found in config"
		return 0
	fi

	log_info "Found $skill_count recommended skill(s)"

	# Install specific skills from recommend-skills.json based on YES_TO_ALL
	# When -y is used, only install: grill-me from matt and 2 react skills from vercel
	local install_count=0
	local max_installs=3
	if [ "$YES_TO_ALL" = true ]; then
		max_installs=3  # grill-me + 2 react skills
	fi

	for i in $(seq 0 $((skill_count - 1))); do
		# When using -y, limit to first 3 skills (grill-me + vercel + expo react skills)
		if [ "$YES_TO_ALL" = true ] && [ "$install_count" -ge "$max_installs" ]; then
			log_info "Reached maximum recommended skills for -y mode ($max_installs), skipping remaining"
			break
		fi
		local repo description skill skill_suffix
		repo=$(echo "$skills_json" | jq -r ".recommended_skills[$i].repo")
		description=$(echo "$skills_json" | jq -r ".recommended_skills[$i].description")
		skill=$(echo "$skills_json" | jq -r ".recommended_skills[$i].skill // empty")
		skill_suffix=""
		[ -n "$skill" ] && skill_suffix="/$skill"

		log_info "  - $repo${skill_suffix}: $description"
		install_single_recommended_skill "$repo" "$skill" "$skill_suffix"
		install_count=$((install_count + 1))
	done

	log_success "Recommended skills check complete"
}

install_single_recommended_skill() {
	local repo="$1"
	local skill="$2"
	local skill_suffix="$3"

	if [ "$YES_TO_ALL" = true ] || [ ! -t 0 ]; then
		if [ -n "$skill" ]; then
			execute "npx skills add '$repo' --skill '$skill' --yes --global --agent claude-code" 2>/dev/null && log_success "Installed: $repo${skill_suffix}" || log_info "Skipped: $repo${skill_suffix}"
		else
			execute "npx skills add '$repo' --yes --global --agent claude-code" 2>/dev/null && log_success "Installed: $repo" || log_info "Skipped: $repo"
		fi
	elif [ -t 0 ]; then
		if prompt_yn "Install $repo${skill_suffix}"; then
			if [ -n "$skill" ]; then
				execute "npx skills add '$repo' --skill '$skill' --global --agent claude-code" 2>/dev/null && log_success "Installed: $repo${skill_suffix}" || log_warning "Failed to install: $repo${skill_suffix}"
			else
				execute "npx skills add '$repo' --global --agent claude-code" 2>/dev/null && log_success "Installed: $repo" || log_warning "Failed to install: $repo"
			fi
		else
			log_info "Skipped: $repo${skill_suffix}"
		fi
	fi
}

# Helper: Remove skills from tool-specific directories that already exist in global ~/.agents/skills
cleanup_duplicate_skills() {
	local global_skills_dir="$HOME/.agents/skills"

	if [ ! -d "$global_skills_dir" ]; then
		return 0
	fi

	log_info "Cleaning up duplicate skills from tool-specific directories..."

	local -a target_dirs=(
		"$CLAUDE_SKILLS_DIR"
		"$OPENCODE_SKILL_DIR"
		"$CODEX_SKILLS_DIR"
		"$GEMINI_SKILLS_DIR"
	)

	for target_dir in "${target_dirs[@]}"; do
		if [ ! -d "$target_dir" ]; then
			continue
		fi
		for skill_dir in "$target_dir"/*; do
			if [ ! -d "$skill_dir" ]; then
				continue
			fi
			local skill_name
			skill_name=$(basename "$skill_dir")
			if [ -d "$global_skills_dir/$skill_name" ]; then
				execute_quoted rm -rf "$skill_dir"
				log_info "Removed duplicate skill $skill_name from $target_dir/"
			fi
		done
	done
}

# Helper: Check if a skill is in the remote skills list
is_remote_skill() {
	case "$1" in
	prd | ralph | qmd-knowledge | codemap | adr | handoffs | pickup | pr-review | slop | tdd)
		return 0
		;;
	*)
		return 1
		;;
	esac
}

# Helper: Install CLI dependency for community plugins
install_cli_dependency() {
	local name="$1"

	case "$name" in
	plannotator)
		if command -v plannotator &>/dev/null; then
			return 0
		fi
		log_info "Installing Plannotator CLI..."
		local plannotator_checksum
		plannotator_checksum=$(resolve_installer_checksum "plannotator")
		execute_installer "https://plannotator.ai/install.sh" "$plannotator_checksum" "Plannotator CLI" || log_warning "Plannotator installation failed"
		;;
	qmd-knowledge)
		handle_qmd_installation_if_needed
		;;
	worktrunk)
		if command -v wt &>/dev/null || ! command -v brew &>/dev/null; then
			return 0
		fi
		log_info "Installing Worktrunk CLI via Homebrew..."
		if execute "brew install worktrunk"; then
			execute "wt config shell install" || log_warning "Worktrunk shell config failed"
		else
			log_warning "Worktrunk installation failed"
		fi
		;;
	esac
}

install_skills() {
	log_info "Installing Claude Code skills..."

	if ! command -v claude &>/dev/null; then
		log_warning "Claude Code not installed - skipping skill installation"
		return 0
	fi

	# Determine skill installation source
	if [ "${YES_TO_ALL:-false}" = "true" ]; then
		SKILL_INSTALL_SOURCE="local"
	elif [ -t 0 ]; then
		log_info "How would you like to install community skills?"
		printf "1) Local (from skills folder) 2) Remote (from jellydn/my-ai-tools using npx skills) [1/2]: "
		read -r REPLY
		echo
		case "$REPLY" in
		2) SKILL_INSTALL_SOURCE="remote" ;;
		*) SKILL_INSTALL_SOURCE="local" ;;
		esac
	else
		SKILL_INSTALL_SOURCE="local"
	fi

	if [ "$SKILL_INSTALL_SOURCE" = "local" ]; then
		install_local_skills
	else
		install_remote_skills
	fi

	install_recommended_skills
	cleanup_duplicate_skills
}

# Extract compatibility field from SKILL.md
skill_is_compatible_with() {
	local skill_dir="$1"
	local platform="$2"
	local skill_md="$skill_dir/SKILL.md"

	if [ ! -f "$skill_md" ]; then
		return 0
	fi

	local compat_line
	compat_line=$(awk '/^compatibility:/ {print; exit}' "$skill_md" 2>/dev/null)
	[ -z "$compat_line" ] && return 0

	echo "$compat_line" | grep -qi "\\b$platform\\b"
}

install_local_skills() {
	if [ ! -d "$SCRIPT_DIR/skills" ]; then
		log_info "skills folder not found, skipping local skills"
		return 0
	fi

	# Check if global skills directory exists - if so, skip tool-specific copies
	# to avoid conflicts. Global ~/.agents/skills/ is the preferred location.
	if [ -d "$HOME/.agents/skills" ] && [ "$YES_TO_ALL" = true ]; then
		log_info "Global skills directory found at ~/.agents/skills - skipping tool-specific skill copy"
		return 0
	fi

	log_info "Installing skills from local skills folder..."

	# Define target directories
	CLAUDE_SKILLS_DIR="$HOME/.claude/skills"
	OPENCODE_SKILL_DIR="$HOME/.config/opencode/skills"
	CODEX_SKILLS_DIR="$HOME/.agents/skills"
	GEMINI_SKILLS_DIR="$HOME/.gemini/skills"

	# Prepare target directories
	prepare_skills_dir "$CLAUDE_SKILLS_DIR"
	prepare_skills_dir "$OPENCODE_SKILL_DIR"
	prepare_skills_dir "$CODEX_SKILLS_DIR"
	prepare_skills_dir "$GEMINI_SKILLS_DIR"

	# Copy all skills from skills folder to targets
	for skill_dir in "$SCRIPT_DIR/skills"/*; do
		if [ ! -d "$skill_dir" ]; then
			continue
		fi

		local skill_name
		skill_name=$(basename "$skill_dir")

		copy_skill_to_targets "$skill_name" "$skill_dir"
	done
}

prepare_skills_dir() {
	local dir="$1"
	local managed_marker=".my-ai-tools-managed"
	local managed_skill_names=()
	local repo_skill_dir=""

	for repo_skill_dir in "$SCRIPT_DIR/skills"/*; do
		[ -d "$repo_skill_dir" ] || continue
		managed_skill_names+=("$(basename "$repo_skill_dir")")
	done

	if [ -d "$dir" ]; then
		for existing_skill in "$dir"/*; do
			[ -d "$existing_skill" ] || continue
			local existing_name
			existing_name=$(basename "$existing_skill")
			local managed=false

			# Check if this skill is in our managed list
			for managed_name in "${managed_skill_names[@]}"; do
				if [ "$existing_name" = "$managed_name" ]; then
					managed=true
					break
				fi
			done

			# Also check for marker file
			if [ "$managed" = false ] && [ -f "$existing_skill/$managed_marker" ]; then
				managed=true
			fi

			if [ "$managed" = true ]; then
				execute_quoted rm -rf "$existing_skill"
			else
				log_info "Preserving user-managed skill: $existing_skill"
			fi
		done
	fi
	execute_quoted mkdir -p "$dir"
}

copy_skill_to_targets() {
	local skill_name="$1"
	local skill_dir="$2"
	local managed_marker=".my-ai-tools-managed"

	if skill_is_compatible_with "$skill_dir" "claude"; then
		if [[ "$CONFIG_CLAUDE_SKILLS" == "all" ]] || [[ ",$CONFIG_CLAUDE_SKILLS," == *",$skill_name,"* ]]; then
			safe_copy_dir "$skill_dir" "$CLAUDE_SKILLS_DIR/$skill_name"
			execute_quoted touch "$CLAUDE_SKILLS_DIR/$skill_name/$managed_marker"
			log_success "Copied $skill_name to Claude Code"
		else
			log_info "Skipped $skill_name for Claude Code (user deselected)"
		fi
	else
		log_info "Skipped $skill_name for Claude Code (not compatible)"
	fi

	if skill_is_compatible_with "$skill_dir" "opencode"; then
		if [[ "$CONFIG_OPENCODE_SKILLS" == "all" ]] || [[ ",$CONFIG_OPENCODE_SKILLS," == *",$skill_name,"* ]]; then
			safe_copy_dir "$skill_dir" "$OPENCODE_SKILL_DIR/$skill_name"
			execute_quoted touch "$OPENCODE_SKILL_DIR/$skill_name/$managed_marker"
			log_success "Copied $skill_name to OpenCode"
		else
			log_info "Skipped $skill_name for OpenCode (user deselected)"
		fi
	else
		log_info "Skipped $skill_name for OpenCode (not compatible)"
	fi

	if skill_is_compatible_with "$skill_dir" "gemini"; then
		if [[ "$CONFIG_GEMINI_SKILLS" == "all" ]] || [[ ",$CONFIG_GEMINI_SKILLS," == *",$skill_name,"* ]]; then
			safe_copy_dir "$skill_dir" "$GEMINI_SKILLS_DIR/$skill_name"
			execute_quoted touch "$GEMINI_SKILLS_DIR/$skill_name/$managed_marker"
			log_success "Copied $skill_name to Gemini CLI"
		else
			log_info "Skipped $skill_name for Gemini CLI (user deselected)"
		fi
	else
		log_info "Skipped $skill_name for Gemini CLI (not compatible)"
	fi

	if skill_is_compatible_with "$skill_dir" "codex"; then
		if [[ "$CONFIG_CODEX_SKILLS" == "all" ]] || [[ ",$CONFIG_CODEX_SKILLS," == *",$skill_name,"* ]]; then
			safe_copy_dir "$skill_dir" "$CODEX_SKILLS_DIR/$skill_name"
			execute_quoted touch "$CODEX_SKILLS_DIR/$skill_name/$managed_marker"
			log_success "Copied $skill_name to Codex CLI"
		else
			log_info "Skipped $skill_name for Codex CLI (user deselected)"
		fi
	else
		log_info "Skipped $skill_name for Codex CLI (not compatible)"
	fi
}

main() {
	echo "╔══════════════════════════════════════════════════════════════════════╗"
	echo "║                        AI Tools Setup                                ║"
	echo "║  Claude • Gemini • OpenCode • Codex                                  ║"
	echo "╚══════════════════════════════════════════════════════════════════════╝"
	echo

	if [ "$DRY_RUN" = true ]; then
		log_warning "DRY RUN MODE - No changes will be made"
		echo
	fi

	preflight_check
	echo

	check_prerequisites
	echo

	show_selection_menu
	echo

	backup_configs
	echo

	if [ "$INSTALL_CLAUDE" = true ]; then
		install_claude_code
		echo
	fi

	if [ "$INSTALL_OPENCODE" = true ]; then
		install_opencode
		echo
	fi

	if [ "$INSTALL_TOOLING" = true ]; then
		install_global_tools
		echo
	fi

	if [ "$INSTALL_CODEX" = true ]; then
		install_codex
		echo
	fi

	if [ "$INSTALL_GEMINI" = true ]; then
		install_gemini
		echo
	fi

	if [ "$INSTALL_HUB" = true ]; then
		install_shared_mcp
		mcp_hub start
		echo
	fi

	if [ "$INSTALL_BACKENDS" = true ]; then
		setup_backend_services
		echo
	fi

	copy_configurations
	install_skills

	log_success "Setup complete!"
	echo
}


if [ -n "$COMMAND" ]; then
	case "$COMMAND" in
		mcp-hub | mcp_hub)
			mcp-hub "${COMMAND_ARGS[@]}"
			;;
		*)
			log_error "Unknown command: $COMMAND"
			exit 1
			;;
	esac
else
	main
fi
