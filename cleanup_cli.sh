sed -i '/# Track whether Amp is installed/,/AMP_INSTALLED=false/d' cli.sh
sed -i '/install_backlog_if_needed/d' cli.sh
sed -i '/install_backlog_if_needed() {/,/^}/d' cli.sh
sed -i '/copy_config_dir "$HOME\/.config\/amp"/d' cli.sh
sed -i '/copy_config_dir "$HOME\/.config\/kilo"/d' cli.sh
sed -i '/copy_config_dir "$HOME\/.pi"/d' cli.sh
sed -i '/copy_config_dir "$HOME\/.cursor"/d' cli.sh
sed -i '/copy_config_dir "$HOME\/.factory"/d' cli.sh
sed -i '/copy_config_file "$HOME\/.config\/ai-launcher\/config.json"/d' cli.sh

sed -i '/^install_amp() {/,/^}/d' cli.sh
sed -i '/^install_ccs() {/,/^}/d' cli.sh
sed -i '/^install_ai_switcher() {/,/^}/d' cli.sh
sed -i '/^install_kilo() {/,/^}/d' cli.sh
sed -i '/^install_pi() {/,/^}/d' cli.sh
sed -i '/^install_copilot() {/,/^}/d' cli.sh
sed -i '/^install_cursor() {/,/^}/d' cli.sh
sed -i '/^install_factory() {/,/^}/d' cli.sh

# Remove function calls from main()
sed -i '/install_amp/d' cli.sh
sed -i '/install_ccs/d' cli.sh
sed -i '/install_ai_switcher/d' cli.sh
sed -i '/install_kilo/d' cli.sh
sed -i '/install_pi/d' cli.sh
sed -i '/install_copilot/d' cli.sh
sed -i '/install_cursor/d' cli.sh
sed -i '/install_factory/d' cli.sh

# Also remove extra echos left after deleting function calls in main()
