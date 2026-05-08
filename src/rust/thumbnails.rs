// Thumbnail generation and caching
use std::path::{Path, PathBuf};
use std::sync::Arc;
use dashmap::DashMap;
use lru::LruCache;
use std::num::NonZeroUsize;
use tokio::task;
use image::{io::Reader as ImageReader, GenericImageView};
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Thumbnail {
    pub path: PathBuf,
    pub data: Vec<u8>, // PNG encoded
    pub width: u32,
    pub height: u32,
}

pub struct ThumbnailManager {
    cache: Arc<DashMap<PathBuf, Thumbnail>>,
    disk_cache_dir: PathBuf,
}

impl ThumbnailManager {
    pub async fn new() -> Self {
        let cache_dir = dirs::cache_dir()
            .unwrap_or_else(|| PathBuf::from("/tmp"))
            .join("rootlink/thumbnails");

        let _ = tokio::fs::create_dir_all(&cache_dir).await;

        Self {
            cache: Arc::new(DashMap::new()),
            disk_cache_dir: cache_dir,
        }
    }

    pub async fn get_thumbnail(
        &self,
        path: &Path,
        size: u32,
    ) -> Option<Thumbnail> {
        // Check memory cache
        if let Some(thumb) = self.cache.get(path) {
            return Some(thumb.value().clone());
        }

        // Check disk cache
        if let Some(thumb) = self.load_from_disk(path, size).await {
            self.cache.insert(path.to_path_buf(), thumb.clone());
            return Some(thumb);
        }

        None
    }

    pub async fn generate_thumbnail(
        &self,
        path: &Path,
        size: u32,
    ) -> Result<Thumbnail, Box<dyn std::error::Error + Send + Sync>> {
        let path = path.to_path_buf();
        let task_path = path.clone();
        let cache = self.cache.clone();

        let thumbnail = task::spawn_blocking(move || {
            Self::generate_thumbnail_blocking(&task_path, size)
        })
        .await??;

        cache.insert(path.clone(), thumbnail.clone());

        // Save to disk
        let _ = self.save_to_disk(&path, &thumbnail).await;

        Ok(thumbnail)
    }

    fn generate_thumbnail_blocking(path: &Path, size: u32) -> Result<Thumbnail, Box<dyn std::error::Error + Send + Sync>> {
        let ext = path
            .extension()
            .and_then(|e| e.to_str())
            .unwrap_or("");

        match ext {
            "jpg" | "jpeg" | "png" | "gif" | "webp" | "bmp" => {
                Self::generate_image_thumbnail(path, size)
            }
            "pdf" => Self::generate_pdf_thumbnail(path, size),
            _ => Err("Unsupported file type".into()),
        }
    }

    fn generate_image_thumbnail(path: &Path, size: u32) -> Result<Thumbnail, Box<dyn std::error::Error + Send + Sync>> {
        let img = ImageReader::open(path)?
            .decode()?;

        let thumbnail = img.thumbnail(size, size);
        let (width, height) = thumbnail.dimensions();

        let mut png_data = Vec::new();
        use std::io::Write;
        let mut encoder = image::codecs::png::PngEncoder::new(&mut png_data);
        encoder.encode(
            thumbnail.as_bytes(),
            width,
            height,
            image::ColorType::Rgba8.into(),
        )?;

        Ok(Thumbnail {
            path: path.to_path_buf(),
            data: png_data,
            width,
            height,
        })
    }

    fn generate_pdf_thumbnail(path: &Path, _size: u32) -> Result<Thumbnail, Box<dyn std::error::Error + Send + Sync>> {
        // Placeholder for PDF thumbnail generation
        // In production, use pdfium-render or similar
        let blank = vec![0u8; 4096];
        Ok(Thumbnail {
            path: path.to_path_buf(),
            data: blank,
            width: 256,
            height: 256,
        })
    }

    async fn load_from_disk(&self, path: &Path, size: u32) -> Option<Thumbnail> {
        let cache_file = self.get_cache_path(path, size);

        if let Ok(data) = tokio::fs::read(&cache_file).await {
            if let Ok(img) = image::load_from_memory(&data) {
                let (width, height) = img.dimensions();
                return Some(Thumbnail {
                    path: path.to_path_buf(),
                    data,
                    width,
                    height,
                });
            }
        }

        None
    }

    async fn save_to_disk(&self, path: &Path, thumbnail: &Thumbnail) -> Result<(), Box<dyn std::error::Error + Send + Sync>> {
        let cache_file = self.get_cache_path(path, 256);

        if let Some(parent) = cache_file.parent() {
            tokio::fs::create_dir_all(parent).await?;
        }

        tokio::fs::write(&cache_file, &thumbnail.data).await?;
        Ok(())
    }

    fn get_cache_path(&self, path: &Path, size: u32) -> PathBuf {
        use std::collections::hash_map::DefaultHasher;
        use std::hash::{Hash, Hasher};

        let mut hasher = DefaultHasher::new();
        path.hash(&mut hasher);
        let hash = hasher.finish();

        self.disk_cache_dir.join(format!("{}_{}.png", hash, size))
    }

    pub async fn clear_cache(&self) {
        self.cache.clear();

        if let Ok(mut entries) = tokio::fs::read_dir(&self.disk_cache_dir).await {
            while let Ok(Some(entry)) = entries.next_entry().await {
                let _ = tokio::fs::remove_file(entry.path()).await;
            }
        }
    }

    pub async fn preload_directory(&self, path: &Path, size: u32) -> usize {
        let mut count = 0;

        if let Ok(entries) = std::fs::read_dir(path) {
            for entry in entries.take(100) {
                if let Ok(entry) = entry {
                    let path = entry.path();
                    if path.is_file() {
                        if self.generate_thumbnail(&path, size).await.is_ok() {
                            count += 1;
                        }
                    }
                }
            }
        }

        count
    }
}
