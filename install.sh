#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

echo "Starting EnvManager (emanager) installation..."

# 1. Check for Cargo dependency
if ! command -v cargo >/dev/null 2>&1; then
  echo "Error: Cargo is not installed. Please install the Rust toolchain first."
  echo "You can get it from https://rustup.rs/"
  exit 1
fi
echo "✓ Cargo dependency found."

# 2. Build the project in release mode
echo "Building the project in release mode... (This might take a moment)"
cargo build --release
echo "✓ Project built successfully."

# 3. Install the binary to /usr/local/bin
INSTALL_DIR="/usr/local/bin"
EXECUTABLE_NAME="emanager"
SOURCE_PATH="./target/release/$EXECUTABLE_NAME"
TARGET_PATH="$INSTALL_DIR/$EXECUTABLE_NAME"

echo "Installing executable to $TARGET_PATH..."
if [ -w "$INSTALL_DIR" ]; then
  # If we have write permissions, just copy
  cp "$SOURCE_PATH" "$TARGET_PATH"
else
  # Otherwise, we need sudo
  echo "Write permission to $INSTALL_DIR is required. Using sudo."
  sudo cp "$SOURCE_PATH" "$TARGET_PATH"
fi
echo "✓ Executable installed."

# 4. Define the shell function to be added using a single-quoted string literal
# This is the safest way to prevent any premature expansion.
SHELL_FUNCTION='

# emanager shell integration
emanager() {
  case "$1" in
    use|clear)
      # The core of the integration: evaluate the output of the command
      eval "$(command emanager "$@")"
      ;;
    *)
      # For all other commands, just run the executable normally
      command emanager "$@"
      ;;
  esac
}
'

# Fish shell function (different syntax)
FISH_SHELL_FUNCTION='
# emanager shell integration
function emanager
    switch $argv[1]
        case use clear
            # The core of the integration: evaluate the output of the command
            eval (command emanager $argv)
        case "*"
            # For all other commands, just run the executable normally
            command emanager $argv
    end
end
'

# 5. Detect user's shell and update the corresponding config file
DETECTED_SHELL=$(basename "$SHELL")
CONFIG_FILE=""

if [ "$DETECTED_SHELL" = "zsh" ]; then
  CONFIG_FILE="$HOME/.zshrc"
elif [ "$DETECTED_SHELL" = "bash" ]; then
  if [ -f "$HOME/.bash_profile" ]; then
    CONFIG_FILE="$HOME/.bash_profile"
  else
    CONFIG_FILE="$HOME/.bashrc"
  fi
elif [ "$DETECTED_SHELL" = "fish" ]; then
  CONFIG_FILE="$HOME/.config/fish/config.fish"
  # Create fish config directory if it doesn't exist
  mkdir -p "$HOME/.config/fish"
else
  echo "Warning: Could not detect a supported shell (bash, zsh, or fish). Your shell: $DETECTED_SHELL"
  echo "Please add the following function to your shell's startup file manually:"
  echo "$SHELL_FUNCTION"
  # We can still finish successfully even if the shell isn't auto-configured
  exit 0
fi

echo "Attempting to update shell configuration: $CONFIG_FILE"

# Add the function to the config file, but only if it's not already there
if [ "$DETECTED_SHELL" = "fish" ]; then
  # Fish has different syntax
  if grep -q "# emanager shell integration" "$CONFIG_FILE"; then
    echo "✓ Shell function already configured. Skipping."
  else
    echo "Adding emanager function to $CONFIG_FILE..."
    echo "$FISH_SHELL_FUNCTION" >> "$CONFIG_FILE"
    echo "✓ Shell function added."
  fi
else
  # Bash and Zsh use the same syntax
  if grep -q "# emanager shell integration" "$CONFIG_FILE"; then
    echo "✓ Shell function already configured. Skipping."
  else
    echo "Adding emanager function to $CONFIG_FILE..."
    echo "$SHELL_FUNCTION" >> "$CONFIG_FILE"
    echo "✓ Shell function added."
  fi
fi

# 6. Install shell completion
echo "Installing shell completion..."

# Create completion directory if it doesn't exist
COMPLETION_DIR="$HOME/.config/emanager/completion"
mkdir -p "$COMPLETION_DIR"

# Copy completion files
cp "./completion/_emanager" "$COMPLETION_DIR/"
cp "./completion/emanager.bash" "$COMPLETION_DIR/"
cp "./completion/emanager.fish" "$COMPLETION_DIR/"

# Install completion based on detected shell
if [ "$DETECTED_SHELL" = "zsh" ]; then
  # For zsh, copy to standard completion directory
  ZSH_COMPLETION_DIR="$HOME/.config/emanager/completion"
  if ! grep -q "# emanager completion" "$CONFIG_FILE"; then
    echo "" >> "$CONFIG_FILE"
    echo "# emanager completion" >> "$CONFIG_FILE"
    echo "fpath=(~/.config/emanager/completion \$fpath)" >> "$CONFIG_FILE"
    echo "autoload -U compinit && compinit" >> "$CONFIG_FILE"
    echo "✓ Zsh completion installed."
  else
    echo "✓ Zsh completion already configured."
  fi
elif [ "$DETECTED_SHELL" = "bash" ]; then
  # For bash, source the completion script
  if ! grep -q "# emanager completion" "$CONFIG_FILE"; then
    echo "" >> "$CONFIG_FILE"
    echo "# emanager completion" >> "$CONFIG_FILE"
    echo "source ~/.config/emanager/completion/emanager.bash" >> "$CONFIG_FILE"
    echo "✓ Bash completion installed."
  else
    echo "✓ Bash completion already configured."
  fi
elif [ "$DETECTED_SHELL" = "fish" ]; then
  # For fish, copy to fish completion directory
  FISH_COMPLETION_DIR="$HOME/.config/fish/completions"
  mkdir -p "$FISH_COMPLETION_DIR"
  cp "./completion/emanager.fish" "$FISH_COMPLETION_DIR/"
  echo "✓ Fish completion installed."
fi

# 7. Final instructions
echo ""
echo "🎉 Installation complete!"
echo ""
echo "Features installed:"
echo "  ✓ emanager command-line tool"
echo "  ✓ Shell integration (use/clear commands)"
echo "  ✓ Tab completion for preset names"
echo ""
echo "For the changes to take effect, please either restart your terminal or run:"
echo "  source $CONFIG_FILE"
echo ""
if [ "$DETECTED_SHELL" = "zsh" ]; then
  echo "NOTE for Powerlevel10k users:"
  echo "If you see warnings about console output during initialization,"
  echo "the emanager configuration has been added to the end of your .zshrc."
  echo "This is safe and won't affect functionality."
  echo ""
fi
echo "You can now use:"
echo "  emanager add myproject API_KEY=abc123"
echo "  emanager use <TAB>  # Tab completion will show available presets"
echo "  emanager show <TAB> # Tab completion works here too"