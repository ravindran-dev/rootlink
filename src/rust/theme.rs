// Theme management
use serde::{Deserialize, Serialize};
use std::path::PathBuf;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum ThemeMode {
    Light,
    Dark,
    System,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ThemeColors {
    pub background: String,
    pub foreground: String,
    pub accent: String,
    pub sidebar_bg: String,
    pub toolbar_bg: String,
    pub border: String,
    pub text_primary: String,
    pub text_secondary: String,
    pub hover_bg: String,
    pub selected_bg: String,
}

impl ThemeColors {
    pub fn light() -> Self {
        Self {
            background: "#FFFFFF".to_string(),
            foreground: "#F5F5F5".to_string(),
            accent: "#0071E3".to_string(),
            sidebar_bg: "#FAFAFA".to_string(),
            toolbar_bg: "#FFFFFF".to_string(),
            border: "#E5E5E5".to_string(),
            text_primary: "#000000".to_string(),
            text_secondary: "#666666".to_string(),
            hover_bg: "#F0F0F0".to_string(),
            selected_bg: "#E8E8E8".to_string(),
        }
    }

    pub fn dark() -> Self {
        Self {
            background: "#1E1E1E".to_string(),
            foreground: "#2A2A2A".to_string(),
            accent: "#0A84FF".to_string(),
            sidebar_bg: "#252525".to_string(),
            toolbar_bg: "#1E1E1E".to_string(),
            border: "#404040".to_string(),
            text_primary: "#FFFFFF".to_string(),
            text_secondary: "#999999".to_string(),
            hover_bg: "#333333".to_string(),
            selected_bg: "#404040".to_string(),
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Theme {
    pub mode: ThemeMode,
    pub colors: ThemeColors,
    pub font_family: String,
    pub font_size: f32,
    pub border_radius: f32,
    pub animation_duration: u32,
    pub blur_enabled: bool,
}

impl Default for Theme {
    fn default() -> Self {
        Self {
            mode: ThemeMode::System,
            colors: ThemeColors::dark(),
            font_family: "SF Pro Display".to_string(),
            font_size: 13.0,
            border_radius: 12.0,
            animation_duration: 200,
            blur_enabled: true,
        }
    }
}

impl Theme {
    pub fn apply_system_preference() -> Self {
        let mut theme = Self::default();

        // Detect system dark mode preference
        if std::env::var("GTK_THEME")
            .map(|t| t.contains("dark"))
            .unwrap_or(false)
        {
            theme.mode = ThemeMode::Dark;
            theme.colors = ThemeColors::dark();
        } else {
            theme.mode = ThemeMode::Light;
            theme.colors = ThemeColors::light();
        }

        theme
    }

    pub fn get_config_dir() -> PathBuf {
        dirs::config_dir()
            .unwrap_or_else(|| PathBuf::from(".config"))
            .join("rootlink")
    }

    pub fn load() -> Result<Self, Box<dyn std::error::Error>> {
        let config_path = Self::get_config_dir().join("theme.json");

        if config_path.exists() {
            let content = std::fs::read_to_string(&config_path)?;
            Ok(serde_json::from_str(&content)?)
        } else {
            Ok(Self::apply_system_preference())
        }
    }

    pub fn save(&self) -> Result<(), Box<dyn std::error::Error>> {
        let config_dir = Self::get_config_dir();
        std::fs::create_dir_all(&config_dir)?;

        let config_path = config_dir.join("theme.json");
        let content = serde_json::to_string_pretty(self)?;
        std::fs::write(&config_path, content)?;

        Ok(())
    }
}
