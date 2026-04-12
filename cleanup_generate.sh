sed -i '/^generate_amp_configs() {/,/^}/d' generate.sh
sed -i '/^generate_kilo_configs() {/,/^}/d' generate.sh
sed -i '/^generate_pi_configs() {/,/^}/d' generate.sh
sed -i '/^generate_copilot_configs() {/,/^}/d' generate.sh
sed -i '/^generate_cursor_configs() {/,/^}/d' generate.sh
sed -i '/^generate_factory_configs() {/,/^}/d' generate.sh
sed -i '/^generate_ai_launcher_configs() {/,/^}/d' generate.sh

# Remove function calls from main()
sed -i '/generate_amp_configs/d' generate.sh
sed -i '/generate_kilo_configs/d' generate.sh
sed -i '/generate_pi_configs/d' generate.sh
sed -i '/generate_copilot_configs/d' generate.sh
sed -i '/generate_cursor_configs/d' generate.sh
sed -i '/generate_factory_configs/d' generate.sh
sed -i '/generate_ai_launcher_configs/d' generate.sh

# Now handle README.md to remove sections for the deleted tools
# Using perl since sed multiline matching is painful
# We can match headers and delete until next major/minor header.

