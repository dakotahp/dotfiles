#!/bin/bash

# Script to create local configuration files if they don't exist
# These files are for machine-specific configurations that shouldn't be tracked in dotfiles

HOME_DIR="$HOME"
COMMENT="# Add local machine-specific things here"

# Function to create a local file if it doesn't exist
create_local_file() {
    local file_path="$1"
    local file_name="$2"

    if [ ! -f "$file_path" ]; then
        echo "Creating $file_name..."
        echo "$COMMENT" > "$file_path"
        echo "Created $file_name at $file_path"
    else
        echo "$file_name already exists at $file_path"
    fi
}

echo "Checking for local configuration files..."

# Create .zshrc.local if it doesn't exist
create_local_file "$HOME_DIR/.zshrc.local" ".zshrc.local"

# Create .gitconfig.local if it doesn't exist
create_local_file "$HOME_DIR/.gitconfig.local" ".gitconfig.local"

# Create .aliases.local if it doesn't exist
create_local_file "$HOME_DIR/.aliases.local" ".aliases.local"

echo "Local configuration files check complete!"
