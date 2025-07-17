mod config;

use anyhow::{Context, Result};
use clap::{Parser, Subcommand};
use std::path::PathBuf;
use shell_escape;

/// A simple tool to manage temporary environment variables
#[derive(Parser, Debug)]
#[command(author, version, about, long_about = None)]
struct Cli {
    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand, Debug)]
enum Commands {
    /// Switch to a preset, loading its environment variables
    Use {
        /// The name of the preset to use
        name: String,
    },
    /// Clear any active environment variables set by emanager
    Clear,
    /// List all available presets
    List,
    /// Show the contents of a specific preset
    Show {
        /// The name of the preset to show
        name: String,
    },
    /// Add or update a variable in a preset
    Add {
        /// The name of the preset to modify
        preset_name: String,
        /// The key-value pairs to add (e.g., KEY=VALUE)
        #[arg(required = true)]
        pairs: Vec<String>,
    },
    /// Remove a preset
    Remove {
        /// The name of the preset to remove
        name: String,
    },
    /// Manage the configuration file path
    Config {
        #[command(subcommand)]
        config_command: ConfigCommands,
    },
}

#[derive(Subcommand, Debug)]
enum ConfigCommands {
    /// Set the path to the presets JSON file
    SetPath {
        /// The new path for the presets file
        path: PathBuf,
    },
    /// Get the current path of the presets JSON file
    GetPath,
}

fn main() -> Result<()> {
    // The config module handles directory/file creation implicitly on first load
    config::get_config_dir()?;

    let cli = Cli::parse();

    match cli.command {
        Commands::Use { name } => use_preset(&name)?,
        Commands::Clear => clear_preset()?,
        Commands::List => list_presets()?,
        Commands::Show { name } => show_preset(&name)?,
        Commands::Add { preset_name, pairs } => add_to_preset(&preset_name, pairs)?,
        Commands::Remove { name } => remove_preset(&name)?,
        Commands::Config { config_command } => handle_config(config_command)?,
    }

    Ok(())
}

// --- Command Implementations ---

fn use_preset(name: &str) -> Result<()> {
    // First, generate the clear script for the currently active preset
    clear_preset()?;

    // Now, generate the export script for the new preset
    let presets = config::load_presets()?;
    let preset = presets
        .get(name)
        .with_context(|| format!("Preset '{}' not found.", name))?;

    for (key, value) in preset {
        // Use shell-escape to handle special characters in values
        let escaped_value = shell_escape::escape(value.into());
        println!(r#"export {}={};"#, key, escaped_value);
    }

    // Finally, save the new state
    config::save_active_preset_name(name)?;
    Ok(())
}

fn clear_preset() -> Result<()> {
    if let Some(active_preset_name) = config::load_active_preset_name()? {
        if let Ok(presets) = config::load_presets() {
            if let Some(preset) = presets.get(&active_preset_name) {
                for key in preset.keys() {
                    println!("unset {};", key);
                }
            }
        }
        config::clear_active_preset_name()?;
    }
    Ok(())
}

fn list_presets() -> Result<()> {
    let presets = config::load_presets()?;
    if presets.is_empty() {
        println!("No presets found. Use 'emanager add ...' to create one.");
        return Ok(());
    }

    println!("Available presets:");
    let mut sorted_keys: Vec<_> = presets.keys().collect();
    sorted_keys.sort();

    for name in sorted_keys {
        println!("- {}", name);
    }
    Ok(())
}

fn show_preset(name: &str) -> Result<()> {
    let presets = config::load_presets()?;
    match presets.get(name) {
        Some(preset) => {
            println!("[{}]", name);
            let mut sorted_keys: Vec<_> = preset.keys().collect();
            sorted_keys.sort();
            for key in sorted_keys {
                println!("  {}={}", key, preset.get(key).unwrap());
            }
        }
        None => {
            anyhow::bail!("Preset '{}' not found.", name);
        }
    }
    Ok(())
}

fn add_to_preset(preset_name: &str, pairs: Vec<String>) -> Result<()> {
    let mut presets = config::load_presets()?;
    let preset = presets.entry(preset_name.to_string()).or_default();

    for pair in pairs {
        let parts: Vec<&str> = pair.splitn(2, '=').collect();
        if parts.len() != 2 || parts[0].is_empty() {
            anyhow::bail!("Invalid key-value pair format: '{}'. Use KEY=VALUE.", pair);
        }
        preset.insert(parts[0].to_string(), parts[1].to_string());
    }

    config::save_presets(&presets)?;
    println!("Successfully updated preset '{}'.", preset_name);
    Ok(())
}

fn remove_preset(name: &str) -> Result<()> {
    let mut presets = config::load_presets()?;
    if presets.remove(name).is_some() {
        config::save_presets(&presets)?;
        println!("Successfully removed preset '{}'.", name);
    } else {
        anyhow::bail!("Preset '{}' not found.", name);
    }
    Ok(())
}

fn handle_config(command: ConfigCommands) -> Result<()> {
    match command {
        ConfigCommands::SetPath { path } => {
            let mut config = config::load_config()?;
            let new_path = if path.is_absolute() {
                path.clone()
            } else {
                std::env::current_dir()?.join(&path)
            };
            
            if !new_path.exists() {
                 if let Some(parent) = new_path.parent() {
                    std::fs::create_dir_all(parent)
                        .with_context(|| format!("Failed to create directory for presets file at {}", parent.display()))?;
                }
                std::fs::File::create(&new_path)
                     .with_context(|| format!("Failed to create presets file at {}", new_path.display()))?;
            }

            config.presets_path = new_path.canonicalize()
                .with_context(|| format!("Failed to find absolute path for {}", path.display()))?;

            config::save_config(&config)?;
            println!("Presets path set to: {}", config.presets_path.display());
        }
        ConfigCommands::GetPath => {
            let path = config::get_presets_path()?;
            println!("Current presets file path is: {}", path.display());
        }
    }
    Ok(())
}
