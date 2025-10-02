# Storage System Documentation

This document details MineContext's storage architecture, backends, and data management.

## 🏗️ Storage Architecture

MineContext uses a **dual-storage architecture** to optimize for different data access patterns:

```
┌─────────────────────────────────────────────────────┐
│              Unified Storage Layer                   │
│  (opencontext/storage/unified_storage.py)           │
└──────────────┬────────────────────────┬─────────────┘
               │                        │
               ▼                        ▼
┌──────────────────────┐    ┌─────────────────────────┐
│  Document Storage    │    │   Vector Storage        │
│  (Structured Data)   │    │   (Embeddings)          │
│                      │    │                         │
│  Backend: SQLite     │    │  Backends:              │
│                      │    │  - ChromaDB             │
│  Stores:             │    │  - VikingDB             │
│  - Metadata          │    │                         │
│  - Content text      │    │  Stores:                │
│  - Relationships     │    │  - Vector embeddings    │
│  - Chunks            │    │  - Similarity search    │
└──────────────────────┘    └─────────────────────────┘
```

## 📦 Storage Components

### 1. Unified Storage (`unified_storage.py`)

The main interface that abstracts underlying storage backends.

**Key Responsibilities:**
- Route operations to appropriate backend
- Coordinate between document and vector storage
- Handle complex queries spanning both backends
- Manage transactions and consistency

**Main Methods:**

```python
class UnifiedStorage:
    # Context Operations
    def insert_processed_context(self, context: ProcessedContext) -> str
    def get_processed_context(self, doc_id: str) -> Optional[ProcessedContext]
    def update_processed_context(self, doc_id: str, context: ProcessedContext) -> bool
    def delete_processed_context(self, doc_id: str) -> bool
    
    # Vector Operations
    def vector_search(self, query: str, top_k: int, filters: Dict) -> List[QueryResult]
    
    # Batch Operations
    def batch_upsert_processed_context(self, contexts: List[ProcessedContext]) -> bool
    
    # Vault Operations (Documents)
    def insert_vaults(self, title: str, content: str, **kwargs) -> int
    def get_vault(self, doc_id: int) -> Optional[Dict]
    def update_vault(self, doc_id: int, **kwargs) -> bool
    def delete_vault(self, doc_id: int) -> bool
```

### 2. Document Storage (SQLite)

Stores structured data with full ACID compliance.

**Database Schema:**

```sql
-- Processed Contexts Table
CREATE TABLE processed_contexts (
    doc_id TEXT PRIMARY KEY,
    context_type TEXT NOT NULL,
    title TEXT,
    summary TEXT,
    content TEXT,
    source TEXT,
    create_time TIMESTAMP,
    update_time TIMESTAMP,
    importance INTEGER,
    confidence INTEGER
);

-- Chunks Table
CREATE TABLE chunks (
    chunk_id INTEGER PRIMARY KEY AUTOINCREMENT,
    doc_id TEXT NOT NULL,
    chunk_index INTEGER,
    text TEXT,
    start_position INTEGER,
    end_position INTEGER,
    metadata TEXT,  -- JSON
    FOREIGN KEY (doc_id) REFERENCES processed_contexts(doc_id)
);

-- Extracted Data Table
CREATE TABLE extracted_data (
    doc_id TEXT PRIMARY KEY,
    keywords TEXT,  -- JSON array
    entities TEXT,  -- JSON array
    tags TEXT,      -- JSON array
    context_type TEXT,
    confidence INTEGER,
    importance INTEGER,
    FOREIGN KEY (doc_id) REFERENCES processed_contexts(doc_id)
);

-- Vaults Table (User Documents)
CREATE TABLE vaults (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    summary TEXT,
    content TEXT,
    tags TEXT,
    document_type TEXT,
    create_time TIMESTAMP,
    update_time TIMESTAMP
);

-- Context Relationships
CREATE TABLE context_relationships (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    source_doc_id TEXT,
    target_doc_id TEXT,
    relationship_type TEXT,
    strength REAL,
    FOREIGN KEY (source_doc_id) REFERENCES processed_contexts(doc_id),
    FOREIGN KEY (target_doc_id) REFERENCES processed_contexts(doc_id)
);

-- Monitoring Metrics
CREATE TABLE monitoring_metrics (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    timestamp TIMESTAMP,
    metric_type TEXT,
    metric_value REAL,
    metadata TEXT  -- JSON
);
```

**Indexes:**
```sql
CREATE INDEX idx_context_type ON processed_contexts(context_type);
CREATE INDEX idx_create_time ON processed_contexts(create_time);
CREATE INDEX idx_chunks_doc_id ON chunks(doc_id);
CREATE INDEX idx_extracted_doc_id ON extracted_data(doc_id);
CREATE INDEX idx_vault_type ON vaults(document_type);
```

### 3. Vector Storage

Stores embeddings for similarity search.

#### ChromaDB Backend (Default)

**Features:**
- Local-first vector database
- No external dependencies
- Persistent storage
- Fast similarity search

**Configuration:**
```yaml
storage:
  vector:
    backend: chromadb
    chromadb:
      persist_directory: ./data/chromadb
      collection_name: minecontext
      distance_metric: cosine
```

**Collections:**
- `minecontext_titles` - Title embeddings
- `minecontext_summaries` - Summary embeddings
- `minecontext_chunks` - Chunk embeddings

**Metadata Stored:**
```python
{
    "doc_id": "abc123",
    "chunk_index": 0,
    "context_type": "ACTIVITY",
    "create_time": "2025-01-01T12:00:00",
    "importance": 5
}
```

#### VikingDB Backend (Optional)

**Features:**
- Cloud-based vector database
- Scalable for large datasets
- High availability
- Enterprise features

**Configuration:**
```yaml
storage:
  vector:
    backend: vikingdb
    vikingdb:
      api_key: your-key
      host: api-vikingdb.volces.com
      region: cn-beijing
      collection_name: minecontext
```

## 🔄 Data Flow

### Insert Flow

```python
# 1. Create ProcessedContext
context = ProcessedContext(
    doc_id="abc123",
    title="My Document",
    content="Full content...",
    chunks=[...],
    extracted_data=ExtractedData(...)
)

# 2. Insert via UnifiedStorage
storage.insert_processed_context(context)
    │
    ├─> Insert into SQLite
    │   ├─ processed_contexts table
    │   ├─ chunks table
    │   └─ extracted_data table
    │
    └─> Generate embeddings and insert into Vector DB
        ├─ Title embedding
        ├─ Summary embedding
        └─ Chunk embeddings
```

### Query Flow

```python
# 1. User query
query = "machine learning projects"

# 2. Generate query embedding
query_embedding = embedding_client.embed(query)

# 3. Search vector database
vector_results = vector_db.search(
    embedding=query_embedding,
    top_k=10,
    where={"context_type": "DOCUMENT"}
)

# 4. Fetch full contexts from SQLite
contexts = []
for result in vector_results:
    context = document_db.get(result.doc_id)
    context.score = result.score
    contexts.append(context)

# 5. Return ranked results
return contexts
```

## 💾 Storage Backend Details

### SQLite Backend

**File Location:** `./data/minecontext.db`

**Advantages:**
- Zero configuration
- ACID compliance
- Excellent for local storage
- Single file database

**Limitations:**
- Single writer at a time
- Limited concurrent access
- Not suitable for distributed systems

**Optimization:**
```python
# Connection pooling
PRAGMA journal_mode=WAL;  # Write-Ahead Logging
PRAGMA synchronous=NORMAL;
PRAGMA cache_size=-64000;  # 64MB cache
PRAGMA temp_store=MEMORY;
```

**Backup:**
```bash
# Backup database
sqlite3 data/minecontext.db ".backup data/backup.db"

# Restore from backup
sqlite3 data/minecontext.db ".restore data/backup.db"
```

### ChromaDB Backend

**Storage Location:** `./data/chromadb/`

**Architecture:**
- DuckDB for metadata
- Local file system for vectors
- HNSW index for similarity search

**Distance Metrics:**

1. **Cosine Similarity** (Default)
   - Best for semantic similarity
   - Ignores magnitude, focuses on direction
   - Range: -1 to 1 (1 = most similar)

2. **L2 (Euclidean)**
   - Considers both direction and magnitude
   - Good for numerical features
   - Lower = more similar

3. **Inner Product**
   - Dot product of vectors
   - Fast computation
   - Higher = more similar

**Performance Tuning:**
```python
# Batch operations
embeddings = [embed(text) for text in texts]
collection.add(
    embeddings=embeddings,
    documents=texts,
    ids=ids,
    metadatas=metadatas
)

# Query optimization
results = collection.query(
    query_embeddings=[query_embedding],
    n_results=10,
    where={"context_type": "DOCUMENT"},  # Filter in DB
    include=["metadatas", "distances"]  # Only fetch needed
)
```

## 🔍 Query Capabilities

### Document Storage Queries

**Basic Queries:**
```python
# Get by ID
context = storage.get_processed_context("abc123")

# Get by type
contexts = storage.query_contexts(
    context_type="ACTIVITY",
    limit=50
)

# Get by date range
contexts = storage.query_contexts(
    start_date="2025-01-01",
    end_date="2025-01-31"
)
```

**Complex Queries:**
```python
# Multi-criteria
contexts = storage.query_contexts(
    context_type="DOCUMENT",
    tags=["AI", "machine-learning"],
    min_importance=5,
    order_by="create_time DESC",
    limit=20
)

# Full-text search
contexts = storage.search_contexts(
    query="artificial intelligence",
    context_types=["DOCUMENT", "NOTE"]
)
```

### Vector Storage Queries

**Similarity Search:**
```python
# Basic similarity
results = storage.vector_search(
    query="machine learning concepts",
    top_k=10
)

# With filters
results = storage.vector_search(
    query="project planning",
    top_k=5,
    filters={
        "context_type": "DOCUMENT",
        "create_time": {"$gte": "2025-01-01"}
    }
)

# Hybrid search (vector + keyword)
results = storage.hybrid_search(
    query="deep learning",
    keywords=["neural", "network"],
    top_k=10
)
```

## 📊 Storage Management

### Storage Statistics

```python
stats = storage.get_storage_stats()
# Returns:
{
    "document_count": 1000,
    "total_size_mb": 512,
    "vector_count": 5000,
    "oldest_context": "2025-01-01T00:00:00",
    "newest_context": "2025-01-31T23:59:59"
}
```

### Maintenance Operations

**Vacuum (Optimize Database):**
```python
storage.vacuum()  # Reclaim space, optimize indexes
```

**Rebuild Indexes:**
```python
storage.rebuild_indexes()  # Rebuild vector indexes
```

**Data Integrity Check:**
```python
issues = storage.check_integrity()
# Returns list of any inconsistencies
```

### Data Cleanup

**Delete Old Contexts:**
```python
# Delete contexts older than 30 days
storage.delete_old_contexts(days=30)
```

**Clear Cache:**
```python
storage.clear_cache()
```

## 🔐 Data Privacy & Security

### Encryption (Future)

Currently, data is stored unencrypted locally. Future versions will support:

- Database encryption at rest
- Field-level encryption for sensitive data
- Encrypted backups

### Access Control

**Local Storage:**
- File system permissions
- User-level isolation
- No network access required

**API Access:**
- Token-based authentication
- Role-based access control (planned)

## 🚀 Performance Optimization

### Caching Strategy

**In-Memory Cache:**
- LRU cache for frequent queries
- Configurable size (default: 512MB)
- Cache embeddings to reduce API calls

```python
# Cache configuration
storage.configure_cache(
    max_size_mb=512,
    ttl_seconds=3600
)
```

### Batch Operations

**Batch Inserts:**
```python
# More efficient than individual inserts
contexts = [context1, context2, context3, ...]
storage.batch_upsert_processed_context(contexts)
```

**Batch Queries:**
```python
# Fetch multiple contexts at once
doc_ids = ["doc1", "doc2", "doc3"]
contexts = storage.batch_get_processed_context(doc_ids)
```

### Index Optimization

**Regular Maintenance:**
- Vacuum database weekly
- Rebuild indexes monthly
- Update statistics after bulk operations

## 📈 Scalability Considerations

### Current Limits

**SQLite:**
- ~1TB database size
- ~1M contexts recommended
- Single writer limitation

**ChromaDB:**
- ~10M vectors recommended
- Memory proportional to vector count
- Local storage only

### Scaling Strategies

**Horizontal Scaling (Future):**
- PostgreSQL for document storage
- Distributed vector database (Weaviate, Milvus)
- Microservices architecture

**Vertical Scaling:**
- Increase cache size
- SSD for database storage
- More memory for vector operations

## 🔧 Migration & Backup

### Export Data

```python
# Export all contexts
storage.export_contexts("backup/contexts.json")

# Export specific types
storage.export_contexts(
    "backup/documents.json",
    context_types=["DOCUMENT", "NOTE"]
)
```

### Import Data

```python
# Import contexts
storage.import_contexts("backup/contexts.json")
```

### Backup Strategy

**Recommended Approach:**

1. **Daily Backup:**
   ```bash
   # Automated script
   sqlite3 data/minecontext.db ".backup data/backup-$(date +%Y%m%d).db"
   cp -r data/chromadb data/chromadb-backup-$(date +%Y%m%d)
   ```

2. **Keep Last 7 Days:**
   ```bash
   find data/backup-*.db -mtime +7 -delete
   ```

3. **Weekly Cloud Backup:**
   - Upload to cloud storage
   - Encrypt before upload

## 📚 Storage API Reference

### Core Methods

```python
# Context Operations
insert_processed_context(context: ProcessedContext) -> str
get_processed_context(doc_id: str) -> Optional[ProcessedContext]
update_processed_context(doc_id: str, context: ProcessedContext) -> bool
delete_processed_context(doc_id: str) -> bool
query_contexts(filters: Dict, limit: int, offset: int) -> List[ProcessedContext]

# Vector Operations
vector_search(query: str, top_k: int, filters: Dict) -> List[QueryResult]
add_embeddings(doc_id: str, embeddings: Dict[str, List[float]]) -> bool
delete_embeddings(doc_id: str) -> bool

# Vault Operations
insert_vaults(title: str, content: str, ...) -> int
get_vault(doc_id: int) -> Optional[Dict]
update_vault(doc_id: int, ...) -> bool
delete_vault(doc_id: int) -> bool
list_vaults(limit: int, offset: int) -> List[Dict]

# Maintenance
vacuum() -> None
rebuild_indexes() -> None
check_integrity() -> List[str]
get_storage_stats() -> Dict
```

## 🔗 Related Documentation

- [Architecture Overview](./03-architecture-overview.md)
- [Data Flow & Workflow](./04-data-flow-workflow.md)
- [Configuration Guide](./05-configuration-guide.md)
- [Development Guide](./12-development-guide.md)
