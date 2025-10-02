# Configuration Guide

This guide covers all configuration options available in MineContext.

## 📁 Configuration File Location

**Default path:** `config/config.yaml`

**Custom path:** Can be specified when starting:
```bash
python -m opencontext.cli start --config /path/to/config.yaml
```

## 🔧 Configuration Structure

### Complete Configuration Example

```yaml
# Server Configuration
server:
  host: 127.0.0.1
  port: 8765
  debug: false
  workers: 1

# Web Interface Configuration
web:
  enabled: true
  host: localhost
  port: 8080

# Logging Configuration
logging:
  level: INFO  # DEBUG, INFO, WARNING, ERROR, CRITICAL
  format: "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
  file:
    enabled: false
    path: logs/minecontext.log
    max_bytes: 10485760  # 10MB
    backup_count: 5

# Embedding Model Configuration
embedding_model:
  provider: doubao  # Options: openai, doubao
  api_key: your-api-key-here
  model: doubao-embedding-large-text-240915
  base_url: null  # Optional: custom API endpoint
  timeout: 30
  max_retries: 3
  batch_size: 100

# Vision-Language Model Configuration
vlm_model:
  provider: doubao  # Options: openai, doubao
  api_key: your-api-key-here
  model: doubao-seed-1-6-flash-250828
  base_url: null
  timeout: 60
  max_retries: 3
  temperature: 0.7
  max_tokens: 2000

# Language Model Configuration (for generation)
llm_model:
  provider: doubao
  api_key: your-api-key-here
  model: doubao-pro-32k-250115
  base_url: null
  timeout: 60
  temperature: 0.7
  max_tokens: 4000

# Context Capture Configuration
capture:
  enabled: true
  
  # Screenshot Capture
  screenshot:
    enabled: true
    capture_interval: 5  # seconds
    save_path: ./screenshots
    image_format: png  # png, jpg
    quality: 85  # 1-100 for jpg
    max_size: 1920x1080  # Max dimensions
    monitors:
      - 0  # Monitor indices to capture, empty for all
    exclude_apps:  # Apps to exclude from capture
      - "Password Manager"
      - "Banking App"
  
  # Document Monitor
  document:
    enabled: false
    watch_paths:
      - ~/Documents
      - ~/Projects
    file_patterns:
      - "*.md"
      - "*.txt"
      - "*.pdf"
    ignore_patterns:
      - "*.tmp"
      - "*~"
    scan_interval: 60  # seconds

# Context Processing Configuration
processing:
  # Chunking Configuration
  chunking:
    strategy: hybrid  # Options: fixed, semantic, hybrid
    chunk_size: 512  # characters
    chunk_overlap: 50
    min_chunk_size: 100
    max_chunk_size: 1000
  
  # Entity Extraction
  entity_extraction:
    enabled: true
    min_confidence: 0.6
    extract_keywords: true
    extract_entities: true
    extract_tags: true
  
  # Context Merging
  merging:
    enabled: true
    time_window: 900  # seconds (15 minutes)
    similarity_threshold: 0.85
    max_merge_count: 10
    merge_strategies:
      - temporal  # Merge by time proximity
      - semantic  # Merge by content similarity
  
  # Memory Compression
  compression:
    enabled: true
    interval: 1800  # seconds (30 minutes)
    min_age: 3600  # Only compress contexts older than 1 hour
    compression_ratio: 0.5

# Storage Configuration
storage:
  # Document Storage (SQLite)
  document:
    backend: sqlite
    path: ./data/minecontext.db
    pool_size: 5
    timeout: 30
  
  # Vector Storage
  vector:
    backend: chromadb  # Options: chromadb, vikingdb
    
    # ChromaDB Configuration
    chromadb:
      persist_directory: ./data/chromadb
      collection_name: minecontext
      distance_metric: cosine  # cosine, l2, ip
    
    # VikingDB Configuration (if using vikingdb)
    vikingdb:
      api_key: your-vikingdb-key
      host: api-vikingdb.volces.com
      region: cn-beijing
      scheme: https
      collection_name: minecontext

# Content Generation Configuration
generation:
  # Daily Summary
  daily_summary:
    enabled: true
    schedule: "20:00"  # 8 PM daily
    lookback_hours: 24
    min_contexts: 5
  
  # Weekly Summary
  weekly_summary:
    enabled: true
    schedule: "sunday 20:00"
    min_contexts: 20
  
  # Todo Extraction
  todo_extraction:
    enabled: true
    auto_create: true
    confidence_threshold: 0.7
  
  # Tips Generation
  tips:
    enabled: true
    daily_limit: 3
    min_importance: 5

# Smart Completion Configuration
completion:
  enabled: true
  trigger_mode: auto  # auto, manual
  trigger_characters: [".", " ", "\n"]
  min_trigger_length: 10
  max_suggestions: 3
  context_window: 500  # characters
  cache_size: 1000

# Agent Configuration
agent:
  enabled: true
  max_steps: 10
  timeout: 300  # seconds
  confirmation_required: true
  tools:
    - search_context
    - create_document
    - update_document
    - create_todo
    - search_web  # If enabled

# Monitoring Configuration
monitoring:
  enabled: true
  metrics:
    collection_interval: 60  # seconds
    retention_days: 30
  health_check:
    interval: 60  # seconds

# Privacy Configuration
privacy:
  # Content Filtering
  content_filtering:
    enabled: true
    filter_passwords: true
    filter_credit_cards: true
    filter_ssn: true
    custom_patterns:  # Regex patterns to filter
      - "\\b\\d{3}-\\d{2}-\\d{4}\\b"  # SSN
  
  # Data Retention
  retention:
    screenshots:
      days: 30
      auto_delete: true
    contexts:
      days: 365
      auto_delete: false
    logs:
      days: 7
      auto_delete: true

# Performance Configuration
performance:
  # Thread Pool
  thread_pool:
    max_workers: 5
    queue_size: 100
  
  # Connection Pool
  connection_pool:
    min_connections: 2
    max_connections: 10
  
  # Cache
  cache:
    enabled: true
    max_size_mb: 512
    ttl_seconds: 3600

# Feature Flags
features:
  experimental:
    multi_modal_search: false
    auto_tagging: true
    smart_notifications: false
  beta:
    agent_workflow: true
    smart_completion: true
```

## 🔑 Configuration Sections

### Server Configuration

Controls the FastAPI server settings.

```yaml
server:
  host: 127.0.0.1  # Bind to localhost only
  port: 8765       # Server port
  debug: false     # Enable debug mode
  workers: 1       # Number of worker processes
```

**Production Settings:**
```yaml
server:
  host: 0.0.0.0   # Allow external connections
  port: 8765
  debug: false    # Disable debug in production
  workers: 4      # Multiple workers for performance
```

### LLM Configuration

#### Doubao (ByteDance) Configuration

```yaml
embedding_model:
  provider: doubao
  api_key: your-doubao-api-key
  model: doubao-embedding-large-text-240915

vlm_model:
  provider: doubao
  api_key: your-doubao-api-key
  model: doubao-seed-1-6-flash-250828

llm_model:
  provider: doubao
  api_key: your-doubao-api-key
  model: doubao-pro-32k-250115
```

#### OpenAI Configuration

```yaml
embedding_model:
  provider: openai
  api_key: your-openai-api-key
  model: text-embedding-3-large

vlm_model:
  provider: openai
  api_key: your-openai-api-key
  model: gpt-4-vision-preview

llm_model:
  provider: openai
  api_key: your-openai-api-key
  model: gpt-4-turbo-preview
```

#### Custom API Endpoints

```yaml
embedding_model:
  provider: openai
  api_key: your-key
  model: text-embedding-3-large
  base_url: https://your-custom-endpoint.com/v1
```

### Capture Configuration

#### Screenshot Settings

```yaml
capture:
  screenshot:
    enabled: true
    capture_interval: 5  # Capture every 5 seconds
    
    # Image settings
    image_format: png    # png or jpg
    quality: 85          # For jpg: 1-100
    max_size: 1920x1080  # Resize if larger
    
    # Multi-monitor
    monitors: [0, 1]     # Specific monitors, or [] for all
    
    # Privacy
    exclude_apps:
      - "1Password"
      - "Bitwarden"
```

**Performance Tuning:**
- **Low resource:** interval: 30, quality: 70
- **Balanced:** interval: 5, quality: 85
- **High quality:** interval: 2, quality: 95

#### Document Monitoring

```yaml
capture:
  document:
    enabled: true
    watch_paths:
      - ~/Documents/Notes
      - ~/Projects
    file_patterns:
      - "*.md"
      - "*.txt"
    scan_interval: 60
```

### Processing Configuration

#### Chunking Strategy

```yaml
processing:
  chunking:
    strategy: hybrid
    chunk_size: 512
    chunk_overlap: 50
```

**Strategies:**
- `fixed`: Simple fixed-size chunks
- `semantic`: Respect paragraph/section boundaries
- `hybrid`: Combines both approaches

**Tuning Guidelines:**
- **Long documents:** chunk_size: 1000, overlap: 100
- **Short snippets:** chunk_size: 256, overlap: 25
- **Balanced:** chunk_size: 512, overlap: 50

#### Merging Configuration

```yaml
processing:
  merging:
    enabled: true
    time_window: 900  # 15 minutes
    similarity_threshold: 0.85
```

**Time Window Examples:**
- **Quick sessions:** 300 (5 minutes)
- **Normal work:** 900 (15 minutes)
- **Long sessions:** 1800 (30 minutes)

### Storage Configuration

#### SQLite (Document Storage)

```yaml
storage:
  document:
    backend: sqlite
    path: ./data/minecontext.db
```

#### ChromaDB (Vector Storage)

```yaml
storage:
  vector:
    backend: chromadb
    chromadb:
      persist_directory: ./data/chromadb
      collection_name: minecontext
      distance_metric: cosine
```

**Distance Metrics:**
- `cosine`: Best for semantic similarity
- `l2`: Euclidean distance
- `ip`: Inner product

#### VikingDB (Cloud Vector Storage)

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

### Generation Configuration

#### Scheduled Generation

```yaml
generation:
  daily_summary:
    enabled: true
    schedule: "20:00"  # 8 PM daily
    
  weekly_summary:
    enabled: true
    schedule: "sunday 20:00"  # Sunday 8 PM
```

**Schedule Formats:**
- Time: `"14:30"`
- Day and time: `"monday 09:00"`
- Cron-like: `"*/30 * * * *"` (every 30 min)

### Privacy Configuration

```yaml
privacy:
  content_filtering:
    enabled: true
    filter_passwords: true
    filter_credit_cards: true
    custom_patterns:
      - "\\bAPI[_-]?KEY\\b.*"  # Filter API keys
  
  retention:
    screenshots:
      days: 30
      auto_delete: true
```

## 🔧 Environment Variables

Configuration can also be set via environment variables:

```bash
# Server
export MINECONTEXT_SERVER_HOST=0.0.0.0
export MINECONTEXT_SERVER_PORT=8765

# LLM API Keys
export MINECONTEXT_EMBEDDING_API_KEY=your-key
export MINECONTEXT_VLM_API_KEY=your-key
export MINECONTEXT_LLM_API_KEY=your-key

# Storage
export MINECONTEXT_DB_PATH=./data/minecontext.db
export MINECONTEXT_VECTOR_PATH=./data/chromadb
```

**Priority:** Environment variables override config file values.

## 🎯 Configuration Presets

### Minimal (Low Resource)

```yaml
capture:
  screenshot:
    capture_interval: 30
    quality: 70

processing:
  chunking:
    chunk_size: 256
  merging:
    enabled: false

performance:
  thread_pool:
    max_workers: 2
```

### Balanced (Default)

```yaml
capture:
  screenshot:
    capture_interval: 5
    quality: 85

processing:
  chunking:
    chunk_size: 512
  merging:
    enabled: true

performance:
  thread_pool:
    max_workers: 5
```

### High Performance

```yaml
capture:
  screenshot:
    capture_interval: 2
    quality: 95

processing:
  chunking:
    chunk_size: 1000
  merging:
    enabled: true
    time_window: 300

performance:
  thread_pool:
    max_workers: 10
  cache:
    max_size_mb: 1024
```

## 🔍 Configuration Validation

Validate your configuration:

```bash
python -m opencontext.cli validate --config config/config.yaml
```

## 📚 Related Documentation

- [Getting Started](./01-getting-started.md)
- [Architecture Overview](./03-architecture-overview.md)
- [API Reference](./06-api-reference.md)
