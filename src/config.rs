use anyhow::{Context, Result};
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::fs;
use std::path::PathBuf;

// Type alias for a single preset: HashMap<String, String>
pub type Preset = HashMap<String, String>;
// Type alias for all presets: HashMap<String, Preset>
pub type Presets = HashMap<String, Preset>;

#[derive(Serialize, Deserialize, Debug)]
pub struct AppConfig {
    pub presets_path: PathBuf,
}

impl Default for AppConfig {
    fn default() -> Self {
        AppConfig {
            presets_path: get_default_presets_path().expect("Failed to get default presets path"),
        }
    }
}

// --- Path Functions ---

pub fn get_config_dir() -> Result<PathBuf> {
    let path = dirs::config_dir()
        .context("Could not find config directory")?
        .join("emanager");
    if !path.exists() {
        fs::create_dir_all(&path)?;
    }
    Ok(path)
}

fn get_config_file_path() -> Result<PathBuf> {
    Ok(get_config_dir()?.join("config.json"))
}

pub fn get_state_file_path() -> Result<PathBuf> {
    Ok(get_config_dir()?.join("state"))
}

fn get_default_presets_path() -> Result<PathBuf> {
    Ok(get_config_dir()?.join("presets.json"))
}

// --- Config Functions ---

pub fn load_config() -> Result<AppConfig> {
    let config_path = get_config_file_path()?;
    if !config_path.exists() {
        // If it doesn't exist, create it with default values
        let config = AppConfig::default();
        save_config(&config)?;
        return Ok(config);
    }

    let content = fs::read_to_string(config_path)?;
    let config: AppConfig = serde_json::from_str(&content).context("Failed to parse config.json")?;
    Ok(config)
}

pub fn save_config(config: &AppConfig) -> Result<()> {
    let config_path = get_config_file_path()?;
    let content = serde_json::to_string_pretty(config)?;
    fs::write(config_path, content)?;
    Ok(())
}

// --- Presets Functions ---

pub fn get_presets_path() -> Result<PathBuf> {
    let config = load_config()?;
    Ok(config.presets_path)
}

pub fn load_presets() -> Result<Presets> {
    let presets_path = get_presets_path()?;
    if !presets_path.exists() {
        // If it doesn't exist, create an empty one and return it
        save_presets(&Presets::new())?;
        return Ok(Presets::new());
    }

    let content = fs::read_to_string(&presets_path)
        .with_context(|| format!("Failed to read presets file at {}", presets_path.display()))?;
        
    if content.trim().is_empty() {
        return Ok(Presets::new());
    }

    let presets: Presets = serde_json::from_str(&content)
        .with_context(|| format!("Failed to parse presets file at {}. It might be malformed JSON.", presets_path.display()))?;
    Ok(presets)
}

pub fn save_presets(presets: &Presets) -> Result<()> {
    let presets_path = get_presets_path()?;
    let content = serde_json::to_string_pretty(presets)?;
    fs::write(presets_path, content)?;
    Ok(())
}

// --- State Functions ---

pub fn load_active_preset_name() -> Result<Option<String>> {
    let state_path = get_state_file_path()?;
    if !state_path.exists() {
        return Ok(None);
    }
    let name = fs::read_to_string(state_path)?.trim().to_string();
    if name.is_empty() {
        Ok(None)
    } else {
        Ok(Some(name))
    }
}

pub fn save_active_preset_name(name: &str) -> Result<()> {
    let state_path = get_state_file_path()?;
    fs::write(state_path, name)?;
    Ok(())
}

pub fn clear_active_preset_name() -> Result<()> {
    let state_path = get_state_file_path()?;
    if state_path.exists() {
        fs::remove_file(state_path)?;
    }
    Ok(())
}
