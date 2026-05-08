// Error handling types
use thiserror::Error;

#[derive(Error, Debug)]
pub enum RootlinkError {
    #[error("Filesystem error: {0}")]
    Filesystem(String),

    #[error("IO error: {0}")]
    Io(#[from] std::io::Error),

    #[error("Search error: {0}")]
    Search(String),

    #[error("Thumbnail error: {0}")]
    Thumbnail(String),

    #[error("QML error: {0}")]
    Qml(String),

    #[error("Permission denied")]
    PermissionDenied,

    #[error("Not found")]
    NotFound,

    #[error("Invalid path")]
    InvalidPath,

    #[error("Operation cancelled")]
    Cancelled,
}

pub type Result<T> = std::result::Result<T, RootlinkError>;
