# EnvManager

EnvManager is a command-line tool for quickly switching and managing temporary environment variable sets.

## Features

- **Preset Management**: Group frequently used environment variables into presets for one-command switching.
- **Temporary Scope**: Environment variables are only active in the current shell session and are cleared upon exit.
- **Easy Configuration**: Uses a simple JSON file for configuration, with support for switching between different config files for different projects.
- **Seamless Integration**: Provides a native-like experience such as `emanager use my-preset` through a simple shell function, eliminating the need to manually run `eval`.

## Installation

### Quick Install (Recommended)

An installation script is provided to automate the entire process.

1.  **Clone the project**:
    ```bash
    git clone <repository_url>
    cd EnvManager
    ```

2.  **Run the install script**:
    This script will automatically compile the project, install the executable, and configure your shell.
    ```bash
    chmod +x install.sh
    ./install.sh
    ```

3.  **Reload your shell**:
    After the installation is complete, follow the script's instructions to restart your terminal or run `source ~/.zshrc` (or `~/.bashrc`) to start using the tool.

### Manual Installation

If you prefer to control the installation process manually, follow these steps:

1.  **Build the Project**:
    After cloning the project, run the following command in the root directory to compile it.
    ```bash
    cargo build --release
    ```
    The compiled executable will be located at `./target/release/emanager`.

2.  **Move to PATH**:
    To use the `emanager` command from anywhere, move the executable to a directory included in your system's `PATH` environment variable. A common choice is `/usr/local/bin`.
    ```bash
    sudo mv ./target/release/emanager /usr/local/bin/
    ```

3.  **Configure Your Shell**:
    This is the most crucial step. To allow `emanager use` and `emanager clear` to affect your current shell environment, you need to add the following function to your shell's configuration file.

    - For **Zsh** (default on macOS), add it to `~/.zshrc`.
    - For **Bash**, add it to `~/.bashrc` or `~/.bash_profile`.

    ```bash
    # emanager shell integration
    emanager() {
      case "$1" in
        use|clear)
          eval "$(command emanager "$@")"
          ;;
        *)
          command emanager "$@"
          ;;
      esac
    }
    ```

4.  **Reload Configuration**:
    Open a new terminal window or run the following command in your current session to apply the changes:
    ```bash
    # for Zsh
    source ~/.zshrc

    # for Bash
    source ~/.bashrc
    ```

## Usage

### 1. Create Your First Preset

```bash
# Add a preset named "project1" with two environment variables
emanager add project1 API_KEY=abc-123-xyz ENDPOINT=https://api.project1.dev
```
This will automatically create the `~/.config/emanager/presets.json` file and save your preset.

### 2. Switch and Clear Environments

```bash
# Activate the environment variables for project1
emanager use project1

# Verify it
echo $API_KEY 
# > abc-123-xyz

# Clear all variables set by emanager
emanager clear

# Verify again
echo $API_KEY
# > (output is empty)
```

### 3. Manage Presets

```bash
# List all available presets
emanager list

# Show the details of the "project1" preset
emanager show project1

# Add or update a variable in the "project1" preset
emanager add project1 DEBUG=true

# Remove the "project1" preset
emanager remove project1
```

### 4. Manage Configuration Files

If you want to use different preset files for different projects, you can manage the configuration file path.

```bash
# Get the path of the currently used presets file
emanager config get-path

# Set the presets file to a new path (supports relative and absolute paths)
emanager config set-path ~/Documents/my-other-project/env.json
```
