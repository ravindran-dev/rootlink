// Filesystem operations and metadata handling
use std::fs::{self, Metadata};
use std::path::{Path, PathBuf};
use std::os::unix::fs::MetadataExt;
use std::os::unix::fs::PermissionsExt;
use serde::{Deserialize, Serialize};
use chrono::{DateTime, Local, TimeZone};
use mime::Mime;
use thiserror::Error;
use async_trait::async_trait;
use tokio::fs as async_fs;
use walkdir::WalkDir;
use dashmap::DashMap;
use std::sync::Arc;

#[derive(Error, Debug)]
pub enum FilesystemError {
    #[error("IO error: {0}")]
    IoError(#[from] std::io::Error),
    #[error("Path error: invalid path")]
    InvalidPath,
    #[error("Permission denied")]
    PermissionDenied,
    #[error("Not found")]
    NotFound,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FileInfo {
    pub path: PathBuf,
    pub name: String,
    pub is_dir: bool,
    pub is_symlink: bool,
    pub size: u64,
    pub modified: i64,
    pub created: i64,
    pub permissions: u32,
    pub mime_type: String,
    pub icon_name: String,
    pub is_hidden: bool,
    pub uid: u32,
    pub gid: u32,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DirectoryListing {
    pub path: PathBuf,
    pub files: Vec<FileInfo>,
    pub total_size: u64,
    pub count: usize,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DriveInfo {
    pub path: PathBuf,
    pub name: String,
    pub total_size: u64,
    pub used_size: u64,
    pub available_size: u64,
    pub is_removable: bool,
    pub filesystem_type: String,
}

pub struct FilesystemService {
    cache: Arc<DashMap<PathBuf, DirectoryListing>>,
    drive_cache: Arc<DashMap<PathBuf, DriveInfo>>,
}

impl FilesystemService {
    pub fn new() -> Self {
        Self {
            cache: Arc::new(DashMap::new()),
            drive_cache: Arc::new(DashMap::new()),
        }
    }

    pub async fn list_directory(&self, path: &Path) -> Result<DirectoryListing, FilesystemError> {
        // Check cache
        if let Some(cached) = self.cache.get(path) {
            return Ok(cached.value().clone());
        }

        let path = self.normalize_path(path)?;

        if !path.is_dir() {
            return Err(FilesystemError::InvalidPath);
        }

        let mut files = Vec::new();
        let mut total_size = 0u64;

        for entry_result in fs::read_dir(&path)? {
            if let Ok(entry) = entry_result {
                if let Ok(file_info) = self.get_file_info(&entry.path()).await {
                    total_size += file_info.size;
                    files.push(file_info);
                }
            }
        }

        // Sort by name, directories first
        files.sort_by(|a, b| {
            if a.is_dir != b.is_dir {
                b.is_dir.cmp(&a.is_dir)
            } else {
                a.name.to_lowercase().cmp(&b.name.to_lowercase())
            }
        });

        let count = files.len();
        let listing = DirectoryListing {
            path: path.clone(),
            files,
            total_size,
            count,
        };

        self.cache.insert(path, listing.clone());
        Ok(listing)
    }

    pub async fn get_file_info(&self, path: &Path) -> Result<FileInfo, FilesystemError> {
        let path = self.normalize_path(path)?;

        let metadata = async_fs::metadata(&path).await?;
        let name = path
            .file_name()
            .and_then(|n| n.to_str())
            .unwrap_or("Unknown")
            .to_string();

        let is_hidden = name.starts_with('.');
        let modified = metadata.modified()?
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap()
            .as_secs() as i64;

        let created = metadata.created()
            .ok()
            .and_then(|t| t.duration_since(std::time::UNIX_EPOCH).ok())
            .map(|d| d.as_secs() as i64)
            .unwrap_or(modified);

        let mime_type = self.get_mime_type(&path);
        let icon_name = self.get_icon_for_file(&path, &mime_type);

        Ok(FileInfo {
            path,
            name,
            is_dir: metadata.is_dir(),
            is_symlink: metadata.is_symlink(),
            size: metadata.len(),
            modified,
            created,
            permissions: metadata.permissions().mode(),
            mime_type,
            icon_name,
            is_hidden,
            uid: metadata.uid(),
            gid: metadata.gid(),
        })
    }

    pub async fn copy(&self, src: &Path, dst: &Path, recursive: bool) -> Result<(), FilesystemError> {
        let src = self.normalize_path(src)?;
        let dst = self.normalize_path(dst)?;

        if src.is_dir() && recursive {
            self.copy_recursive(&src, &dst).await?;
        } else if src.is_file() {
            async_fs::copy(&src, &dst).await?;
        }

        self.invalidate_cache(dst.parent());
        Ok(())
    }

    pub async fn move_file(&self, src: &Path, dst: &Path) -> Result<(), FilesystemError> {
        let src = self.normalize_path(src)?;
        let dst = self.normalize_path(dst)?;

        async_fs::rename(&src, &dst).await?;

        self.invalidate_cache(src.parent());
        self.invalidate_cache(dst.parent());
        Ok(())
    }

    pub async fn delete(&self, path: &Path, recursive: bool) -> Result<(), FilesystemError> {
        let path = self.normalize_path(path)?;

        if path.is_dir() && recursive {
            async_fs::remove_dir_all(&path).await?;
        } else if path.is_dir() {
            async_fs::remove_dir(&path).await?;
        } else {
            async_fs::remove_file(&path).await?;
        }

        self.invalidate_cache(path.parent());
        Ok(())
    }

    pub async fn rename(&self, path: &Path, new_name: &str) -> Result<PathBuf, FilesystemError> {
        let path = self.normalize_path(path)?;
        let parent = path.parent().ok_or(FilesystemError::InvalidPath)?;
        let new_path = parent.join(new_name);

        async_fs::rename(&path, &new_path).await?;

        self.invalidate_cache(Some(parent));
        Ok(new_path)
    }

    pub async fn create_directory(&self, path: &Path) -> Result<(), FilesystemError> {
        let path = self.normalize_path(path)?;
        async_fs::create_dir(&path).await?;

        self.invalidate_cache(path.parent());
        Ok(())
    }

    pub async fn set_permissions(&self, path: &Path, mode: u32) -> Result<(), FilesystemError> {
        let path = self.normalize_path(path)?;
        let permissions = fs::Permissions::from_mode(mode);
        async_fs::set_permissions(&path, permissions).await?;

        Ok(())
    }

    pub fn get_home_dir(&self) -> PathBuf {
        dirs::home_dir().unwrap_or_else(|| PathBuf::from("/"))
    }

    pub fn get_mounted_drives(&self) -> Vec<DriveInfo> {
        // Parse /proc/mounts for mounted filesystems
        let mut drives = Vec::new();

        if let Ok(content) = fs::read_to_string("/proc/mounts") {
            for line in content.lines() {
                let parts: Vec<&str> = line.split_whitespace().collect();
                if parts.len() >= 2 {
                    let mount_path = PathBuf::from(parts[1]);
                    if let Ok(info) = self.get_drive_info(&mount_path) {
                        drives.push(info);
                    }
                }
            }
        }

        drives
    }

    fn get_drive_info(&self, path: &Path) -> Result<DriveInfo, FilesystemError> {
        let metadata = fs::metadata(path)?;
        let stat: libc::statvfs = unsafe {
            let mut stat = std::mem::zeroed();
            let c_path = std::ffi::CString::new(path.to_string_lossy().as_bytes())
                .map_err(|_| FilesystemError::InvalidPath)?;
            if libc::statvfs(c_path.as_ptr(), &mut stat) != 0 {
                return Err(FilesystemError::IoError(std::io::Error::last_os_error()));
            }
            stat
        };

        let block_size = stat.f_frsize as u64;
        let total_size = block_size * stat.f_blocks;
        let available_size = block_size * stat.f_bavail;
        let used_size = total_size - available_size;

        let name = path
            .file_name()
            .and_then(|n| n.to_str())
            .unwrap_or("Mount")
            .to_string();

        Ok(DriveInfo {
            path: path.to_path_buf(),
            name,
            total_size,
            used_size,
            available_size,
            is_removable: self.is_removable_media(path),
            filesystem_type: String::from("unknown"),
        })
    }

    fn normalize_path(&self, path: &Path) -> Result<PathBuf, FilesystemError> {
        let path = if path.starts_with("~") {
            self.get_home_dir().join(path.strip_prefix("~").unwrap_or(Path::new("")))
        } else {
            path.to_path_buf()
        };

        Ok(std::fs::canonicalize(&path).unwrap_or(path))
    }

    fn get_mime_type(&self, path: &Path) -> String {
        path.extension()
            .and_then(|ext| ext.to_str())
            .and_then(|ext| {
                let guesses = mime_guess::from_ext(ext);
                guesses.first().cloned()
            })
            .unwrap_or_else(|| "application/octet-stream".to_string())
    }

    fn get_icon_for_file(&self, path: &Path, mime_type: &str) -> String {
        if path.is_dir() {
            return "folder".to_string();
        }

        let ext = path
            .extension()
            .and_then(|e| e.to_str())
            .unwrap_or("");

        match ext {
            "pdf" => "document-pdf",
            "doc" | "docx" => "document-text",
            "xls" | "xlsx" => "table",
            "ppt" | "pptx" => "presentation",
            "txt" | "md" | "rs" | "py" | "js" | "ts" => "document-code",
            "jpg" | "jpeg" | "png" | "gif" | "webp" | "svg" => "image",
            "mp4" | "mkv" | "avi" | "mov" => "video",
            "mp3" | "wav" | "flac" | "m4a" => "audio",
            "zip" | "rar" | "7z" | "tar" | "gz" => "archive",
            "app" | "bin" | "exe" => "executable",
            _ if mime_type.starts_with("image/") => "image",
            _ if mime_type.starts_with("video/") => "video",
            _ if mime_type.starts_with("audio/") => "audio",
            _ => "file",
        }.to_string()
    }

    async fn copy_recursive(&self, src: &Path, dst: &Path) -> Result<(), FilesystemError> {
        async_fs::create_dir_all(dst).await?;

        for entry in WalkDir::new(src)
            .into_iter()
            .filter_map(|e| e.ok())
        {
            let path = entry.path();
            let relative = path.strip_prefix(src).unwrap_or(path);
            let target = dst.join(relative);

            if path.is_dir() {
                async_fs::create_dir_all(&target).await?;
            } else {
                async_fs::copy(path, &target).await?;
            }
        }

        Ok(())
    }

    fn invalidate_cache(&self, path: Option<&Path>) {
        if let Some(p) = path {
            self.cache.remove(p);
        }
    }

    fn is_removable_media(&self, path: &Path) -> bool {
        let path_str = path.to_string_lossy().to_string();
        path_str.contains("/mnt/") || path_str.contains("/media/")
    }
}

// For mime_guess compatibility
mod mime_guess {
    use super::*;

    pub fn from_ext(ext: &str) -> Vec<String> {
        match ext {
            "pdf" => vec!["application/pdf".to_string()],
            "txt" => vec!["text/plain".to_string()],
            "jpg" | "jpeg" => vec!["image/jpeg".to_string()],
            "png" => vec!["image/png".to_string()],
            "gif" => vec!["image/gif".to_string()],
            "webp" => vec!["image/webp".to_string()],
            "mp4" => vec!["video/mp4".to_string()],
            "mkv" => vec!["video/x-matroska".to_string()],
            "mp3" => vec!["audio/mpeg".to_string()],
            "wav" => vec!["audio/wav".to_string()],
            "zip" => vec!["application/zip".to_string()],
            "md" => vec!["text/markdown".to_string()],
            "rs" => vec!["text/x-rust".to_string()],
            "py" => vec!["text/x-python".to_string()],
            "js" | "ts" => vec!["text/javascript".to_string()],
            _ => vec!["application/octet-stream".to_string()],
        }
    }
}
