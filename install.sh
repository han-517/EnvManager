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
else
  echo "Warning: Could not detect a supported shell (bash or zsh). Your shell: $DETECTED_SHELL"
  echo "Please add the following function to your shell's startup file manually:"
  echo "$SHELL_FUNCTION"
  # We can still finish successfully even if the shell isn't auto-configured
  exit 0
fi

echo "Attempting to update shell configuration: $CONFIG_FILE"

# Add the function to the config file, but only if it's not already there
if grep -q "# emanager shell integration" "$CONFIG_FILE"; then
  echo "✓ Shell function already configured. Skipping."
else
  echo "Adding emanager function to $CONFIG_FILE..."
  echo "$SHELL_FUNCTION" >> "$CONFIG_FILE"
  echo "✓ Shell function added."
fi

# 6. Final instructions
echo ""
echo "🎉 Installation complete!"
echo ""
echo "For the changes to take effect, please either restart your terminal or run:"
echo "  source $CONFIG_FILE"