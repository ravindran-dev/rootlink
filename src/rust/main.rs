mod filesystem;
mod filewatcher;
mod search;
mod thumbnails;
mod qml_bridge;
mod theme;
mod errors;

use std::path::PathBuf;
use tracing_subscriber;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    // Initialize logging
    tracing_subscriber::fmt()
        .with_max_level(tracing::Level::INFO)
        .init();

    tracing::info!("Starting Rootlink File Manager");

    // Initialize filesystem service
    let fs_service = filesystem::FilesystemService::new();

    // Initialize file watcher
    let watcher = filewatcher::FileWatcher::new().await?;

    // Initialize search engine
    let search_engine = search::SearchEngine::new()?;

    // Initialize thumbnail manager
    let thumbnail_mgr = thumbnails::ThumbnailManager::new().await;

    // Start QML application
    qml_bridge::start_qml_application(fs_service, watcher, search_engine, thumbnail_mgr).await?;

    Ok(())
}
