#!/bin/bash

# Cleanup script for emanager installation
echo "Cleaning up previous emanager installation..."

# Function to remove emanager configuration from a file
cleanup_config_file() {
    local file="$1"
    if [ -f "$file" ]; then
        echo "Cleaning up $file..."
        # Create a backup
        cp "$file" "$file.emanager.backup"
        
        # Remove emanager shell integration
        sed -i.tmp '/# emanager shell integration/,/^}$/d' "$file"
        
        # Remove emanager completion
        sed -i.tmp '/# emanager completion/,/^$/d' "$file"
        
        # Clean up temporary files
        rm -f "$file.tmp"
        
        echo "✓ Cleaned up $file"
    fi
}

# Detect shell and clean up appropriate config files
DETECTED_SHELL=$(basename "$SHELL")

if [ "$DETECTED_SHELL" = "zsh" ]; then
    cleanup_config_file "$HOME/.zshrc"
elif [ "$DETECTED_SHELL" = "bash" ]; then
    if [ -f "$HOME/.bash_profile" ]; then
        cleanup_config_file "$HOME/.bash_profile"
    fi
    if [ -f "$HOME/.bashrc" ]; then
        cleanup_config_file "$HOME/.bashrc"
    fi
elif [ "$DETECTED_SHELL" = "fish" ]; then
    cleanup_config_file "$HOME/.config/fish/config.fish"
    # Remove fish completion file
    rm -f "$HOME/.config/fish/completions/emanager.fish"
fi

# Remove emanager completion directory
rm -rf "$HOME/.config/emanager/completion"

# Also remove the zsh completion file if it was copied to the standard location
rm -f "$HOME/.config/emanager/completion/_emanager"

echo ""
echo "✓ Cleanup complete!"
echo "You can now run ./install.sh again for a clean installation."
