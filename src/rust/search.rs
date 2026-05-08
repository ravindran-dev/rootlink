// Full-text search engine with indexing
use rusqlite::{params, Connection, Result as SqlResult};
use std::path::{Path, PathBuf};
use std::sync::{Arc, Mutex};
use regex::Regex;
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SearchResult {
    pub path: PathBuf,
    pub name: String,
    pub relevance: f32,
    pub is_dir: bool,
}

pub struct SearchEngine {
    db: Arc<Mutex<Connection>>,
}

impl SearchEngine {
    pub fn new() -> SqlResult<Self> {
        let db_path = dirs::cache_dir()
            .unwrap_or_else(|| PathBuf::from("/tmp"))
            .join("rootlink_search.db");

        let conn = Connection::open(&db_path)?;
        conn.execute_batch(
            "CREATE TABLE IF NOT EXISTS files (
                id INTEGER PRIMARY KEY,
                path TEXT UNIQUE NOT NULL,
                name TEXT NOT NULL,
                is_dir BOOLEAN NOT NULL,
                mime_type TEXT,
                modified INTEGER,
                indexed_at INTEGER
            );
            CREATE INDEX IF NOT EXISTS idx_name ON files(name);
            CREATE INDEX IF NOT EXISTS idx_path ON files(path);
            CREATE VIRTUAL TABLE IF NOT EXISTS file_search USING fts5(
                name, path, mime_type
            );"
        )?;

        Ok(Self {
            db: Arc::new(Mutex::new(conn)),
        })
    }

    pub fn search(&self, query: &str, limit: usize) -> SqlResult<Vec<SearchResult>> {
        let db = self.db.lock().unwrap();

        // Build search query with relevance scoring
        let search_query = format!(
            "SELECT f.path, f.name, f.is_dir, 
                    CASE 
                        WHEN f.name LIKE '{}%' THEN 1.0
                        WHEN f.name LIKE '%{}%' THEN 0.7
                        ELSE 0.3
                    END as relevance
             FROM files f
             WHERE f.name LIKE '%{}%' OR f.path LIKE '%{}%'
             ORDER BY relevance DESC, f.name ASC
             LIMIT ?",
            query, query, query, query
        );

        let mut stmt = db.prepare(&search_query)?;
        let results = stmt.query_map(params![limit], |row| {
            Ok(SearchResult {
                path: PathBuf::from(row.get::<_, String>(0)?),
                name: row.get(1)?,
                is_dir: row.get(2)?,
                relevance: row.get(3)?,
            })
        })?;

        let mut search_results = Vec::new();
        for result in results {
            search_results.push(result?);
        }

        Ok(search_results)
    }

    pub fn index_file(&self, path: &Path, is_dir: bool, mime_type: &str) -> SqlResult<()> {
        let db = self.db.lock().unwrap();
        let path_str = path.to_string_lossy().to_string();
        let name = path
            .file_name()
            .and_then(|n| n.to_str())
            .unwrap_or("")
            .to_string();

        let now = chrono::Local::now().timestamp();

        db.execute(
            "INSERT OR REPLACE INTO files (path, name, is_dir, mime_type, modified, indexed_at)
             VALUES (?1, ?2, ?3, ?4, ?5, ?6)",
            params![&path_str, &name, is_dir, mime_type, now, now],
        )?;

        Ok(())
    }

    pub fn index_directory(&self, root_path: &Path) -> SqlResult<usize> {
        let db = self.db.lock().unwrap();
        let mut count = 0;

        for entry in walkdir::WalkDir::new(root_path)
            .into_iter()
            .filter_map(|e| e.ok())
            .take(10000) // Limit to prevent long operations
        {
            let path = entry.path();
            let is_dir = path.is_dir();
            let name = path
                .file_name()
                .and_then(|n| n.to_str())
                .unwrap_or("");

            // Skip hidden and system files
            if name.starts_with('.') {
                continue;
            }

            let mime_type = Self::get_mime_type(path);
            let path_str = path.to_string_lossy().to_string();
            let now = chrono::Local::now().timestamp();

            db.execute(
                "INSERT OR REPLACE INTO files (path, name, is_dir, mime_type, modified, indexed_at)
                 VALUES (?1, ?2, ?3, ?4, ?5, ?6)",
                params![&path_str, name, is_dir, mime_type, now, now],
            )?;

            count += 1;
        }

        db.execute_batch("PRAGMA optimize")?;
        Ok(count)
    }

    pub fn clear_index(&self) -> SqlResult<()> {
        let db = self.db.lock().unwrap();
        db.execute("DELETE FROM files", [])?;
        Ok(())
    }

    fn get_mime_type(path: &Path) -> String {
        path
            .extension()
            .and_then(|ext| ext.to_str())
            .map(|ext| match ext {
                "pdf" => "application/pdf",
                "jpg" | "jpeg" => "image/jpeg",
                "png" => "image/png",
                "gif" => "image/gif",
                "txt" => "text/plain",
                "md" => "text/markdown",
                "rs" => "text/x-rust",
                "py" => "text/x-python",
                "js" | "ts" => "text/javascript",
                _ => "application/octet-stream",
            })
            .unwrap_or("application/octet-stream")
            .to_string()
    }
}

use walkdir;
