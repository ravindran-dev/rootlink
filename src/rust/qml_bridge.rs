// QML bridge for Rust/Qt integration
use crate::{
    filesystem::FilesystemService,
    filewatcher::FileWatcher,
    search::SearchEngine,
    thumbnails::ThumbnailManager,
    theme::Theme,
};
use serde_json::json;
use std::sync::Arc;
use tokio::sync::RwLock;

pub struct QmlBridge {
    fs_service: Arc<FilesystemService>,
    file_watcher: Arc<FileWatcher>,
    search_engine: Arc<SearchEngine>,
    thumbnail_manager: Arc<ThumbnailManager>,
    theme: Arc<RwLock<Theme>>,
}

impl QmlBridge {
    pub fn new(
        fs_service: FilesystemService,
        file_watcher: FileWatcher,
        search_engine: SearchEngine,
        thumbnail_manager: ThumbnailManager,
    ) -> Self {
        let theme = Theme::load().unwrap_or_default();

        Self {
            fs_service: Arc::new(fs_service),
            file_watcher: Arc::new(file_watcher),
            search_engine: Arc::new(search_engine),
            thumbnail_manager: Arc::new(thumbnail_manager),
            theme: Arc::new(RwLock::new(theme)),
        }
    }

    pub async fn list_directory(&self, path: &str) -> Result<String, String> {
        let listing = self
            .fs_service
            .list_directory(std::path::Path::new(path))
            .await
            .map_err(|e| format!("Failed to list directory: {}", e))?;

        Ok(serde_json::to_string(&listing).map_err(|e| format!("Serialization error: {}", e))?)
    }

    pub async fn get_file_info(&self, path: &str) -> Result<String, String> {
        let info = self
            .fs_service
            .get_file_info(std::path::Path::new(path))
            .await
            .map_err(|e| format!("Failed to get file info: {}", e))?;

        Ok(serde_json::to_string(&info).map_err(|e| format!("Serialization error: {}", e))?)
    }

    pub async fn search(&self, query: &str) -> Result<String, String> {
        let results = self
            .search_engine
            .search(query, 50)
            .map_err(|e| format!("Search failed: {}", e))?;

        Ok(serde_json::to_string(&results).map_err(|e| format!("Serialization error: {}", e))?)
    }

    pub async fn copy(&self, src: &str, dst: &str) -> Result<(), String> {
        self.fs_service
            .copy(
                std::path::Path::new(src),
                std::path::Path::new(dst),
                true,
            )
            .await
            .map_err(|e| format!("Copy failed: {}", e))
    }

    pub async fn move_file(&self, src: &str, dst: &str) -> Result<(), String> {
        self.fs_service
            .move_file(std::path::Path::new(src), std::path::Path::new(dst))
            .await
            .map_err(|e| format!("Move failed: {}", e))
    }

    pub async fn delete(&self, path: &str) -> Result<(), String> {
        self.fs_service
            .delete(std::path::Path::new(path), true)
            .await
            .map_err(|e| format!("Delete failed: {}", e))
    }

    pub async fn rename(&self, path: &str, new_name: &str) -> Result<String, String> {
        let new_path = self
            .fs_service
            .rename(std::path::Path::new(path), new_name)
            .await
            .map_err(|e| format!("Rename failed: {}", e))?;

        Ok(new_path.to_string_lossy().to_string())
    }

    pub async fn create_directory(&self, path: &str) -> Result<(), String> {
        self.fs_service
            .create_directory(std::path::Path::new(path))
            .await
            .map_err(|e| format!("Create directory failed: {}", e))
    }

    pub async fn get_theme(&self) -> String {
        let theme = self.theme.read().await;
        serde_json::to_string(&*theme).unwrap_or_default()
    }

    pub async fn set_theme(&self, theme_json: &str) -> Result<(), String> {
        let theme: Theme =
            serde_json::from_str(theme_json).map_err(|e| format!("Invalid theme: {}", e))?;

        theme.save().map_err(|e| format!("Save theme failed: {}", e))?;

        let mut current_theme = self.theme.write().await;
        *current_theme = theme;

        Ok(())
    }

    pub fn get_home_directory(&self) -> String {
        self.fs_service
            .get_home_dir()
            .to_string_lossy()
            .to_string()
    }

    pub async fn get_mounted_drives(&self) -> String {
        let drives = self.fs_service.get_mounted_drives();
        serde_json::to_string(&drives).unwrap_or_default()
    }

    pub async fn get_thumbnail(&self, path: &str, size: u32) -> Result<String, String> {
        let path = std::path::Path::new(path);

        if let Some(thumb) = self
            .thumbnail_manager
            .get_thumbnail(path, size)
            .await
        {
            return Ok(serde_json::to_string(&thumb)
                .map_err(|e| format!("Serialization error: {}", e))?);
        }

        self.thumbnail_manager
            .generate_thumbnail(path, size)
            .await
            .map_err(|e| format!("Thumbnail generation failed: {}", e))
            .and_then(|thumb| {
                serde_json::to_string(&thumb)
                    .map_err(|e| format!("Serialization error: {}", e))
            })
    }

    pub async fn index_directory(&self, path: &str) -> Result<usize, String> {
        self.search_engine
            .index_directory(std::path::Path::new(path))
            .map_err(|e| format!("Indexing failed: {}", e))
    }
}

pub async fn start_qml_application(
    fs_service: FilesystemService,
    file_watcher: FileWatcher,
    search_engine: SearchEngine,
    thumbnail_manager: ThumbnailManager,
) -> Result<(), Box<dyn std::error::Error>> {
    let bridge = QmlBridge::new(fs_service, file_watcher, search_engine, thumbnail_manager);

    // In a real implementation, this would start the Qt/QML event loop
    // For now, we just return to allow the program to continue
    // The QML application would be started from the C++ main

    tracing::info!("QML bridge initialized and ready");

    // Keep the service running
    tokio::signal::ctrl_c().await?;

    Ok(())
}
