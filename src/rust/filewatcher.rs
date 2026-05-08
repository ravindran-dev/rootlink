// File system watcher for real-time changes
use notify::{Event, EventKind, RecursiveMode, Watcher, RecommendedWatcher, Config, event::{CreateKind, ModifyKind, RemoveKind, RenameMode}};
use std::path::PathBuf;
use std::sync::mpsc::channel;
use tokio::sync::broadcast;
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum FileChangeEvent {
    Created(PathBuf),
    Modified(PathBuf),
    Deleted(PathBuf),
    Renamed(PathBuf, PathBuf),
}

pub struct FileWatcher {
    tx: broadcast::Sender<FileChangeEvent>,
}

impl FileWatcher {
    pub async fn new() -> Result<Self, Box<dyn std::error::Error>> {
        let (tx, _) = broadcast::channel(100);
        let tx_clone = tx.clone();

        tokio::spawn(async move {
            if let Err(e) = Self::watch_loop(tx_clone).await {
                tracing::error!("File watcher error: {}", e);
            }
        });

        Ok(Self { tx })
    }

    async fn watch_loop(tx: broadcast::Sender<FileChangeEvent>) -> Result<(), Box<dyn std::error::Error>> {
        let (watcher_tx, watcher_rx) = channel();

        let mut watcher: RecommendedWatcher = notify::recommended_watcher(move |result| {
            let _ = watcher_tx.send(result);
        })?;
        watcher.configure(Config::default())?;

        // Watch home directory and common locations
        let home = dirs::home_dir().unwrap_or_else(|| PathBuf::from("/"));
        watcher.watch(&home, RecursiveMode::Recursive)?;

        if let Ok(downloads) = std::fs::read_to_string("/etc/xdg/user-dirs.defaults") {
            for line in downloads.lines() {
                if let Some(path) = line.split('=').nth(1) {
                    let expanded = path.replace("$HOME", home.to_string_lossy().as_ref());
                    let expanded_path = PathBuf::from(expanded);
                    let _ = watcher.watch(&expanded_path, RecursiveMode::Recursive);
                }
            }
        }

        loop {
            match watcher_rx.recv() {
                Ok(Ok(event)) => {
                    if let Some(fs_event) = Self::map_event(event) {
                        let _ = tx.send(fs_event);
                    }
                }
                Ok(Err(e)) => {
                    tracing::warn!("File watcher error: {}", e);
                }
                Err(e) => {
                    tracing::warn!("File watcher channel closed: {}", e);
                    break Ok(());
                }
            }
        }
    }

    fn map_event(event: Event) -> Option<FileChangeEvent> {
        match event.kind {
            EventKind::Create(CreateKind::Any) | EventKind::Create(_) => {
                event.paths.first().cloned().map(FileChangeEvent::Created)
            }
            EventKind::Modify(ModifyKind::Data(_)) | EventKind::Modify(ModifyKind::Any) => {
                event.paths.first().cloned().map(FileChangeEvent::Modified)
            }
            EventKind::Remove(RemoveKind::Any) | EventKind::Remove(_) => {
                event.paths.first().cloned().map(FileChangeEvent::Deleted)
            }
            EventKind::Modify(ModifyKind::Name(RenameMode::Both)) => {
                if event.paths.len() >= 2 {
                    Some(FileChangeEvent::Renamed(event.paths[0].clone(), event.paths[1].clone()))
                } else {
                    None
                }
            }
            _ => None,
        }
    }

    pub fn subscribe(&self) -> broadcast::Receiver<FileChangeEvent> {
        self.tx.subscribe()
    }
}
