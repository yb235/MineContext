# Architecture Overview

This document provides a comprehensive overview of MineContext's architecture, design principles, and component organization.

## 🎯 Design Philosophy

MineContext is built on three core principles:

1. **Modularity**: Components are loosely coupled with well-defined interfaces
2. **Extensibility**: Easy to add new capture sources, processors, and storage backends
3. **Privacy-First**: All data processing happens locally; only LLM API calls go external

## 🏗️ System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        User Interface Layer                      │
│  ┌──────────────┐  ┌──────────────┐  ┌─────────────────────┐  │
│  │ Web Interface│  │  Desktop App │  │   API Endpoints     │  │
│  └──────────────┘  └──────────────┘  └─────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Server/API Layer                            │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ FastAPI Server (opencontext/server/)                     │  │
│  │ - REST API endpoints                                     │  │
│  │ - WebSocket support                                      │  │
│  │ - Static file serving                                    │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Manager Layer                               │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐ │
│  │   Capture    │  │  Processor   │  │   Consumption        │ │
│  │   Manager    │  │   Manager    │  │   Manager            │ │
│  └──────────────┘  └──────────────┘  └──────────────────────┘ │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │              Event Manager (coordination)                │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
          ▼                    ▼                      ▼
┌──────────────────┐ ┌──────────────────┐ ┌──────────────────────┐
│ Context Capture  │ │Context Processing│ │Context Consumption   │
│                  │ │                  │ │                      │
│ - Screenshot     │ │ - Chunking       │ │ - Content Generation│
│ - Documents      │ │ - Entity Extract │ │ - Smart Completion  │
│ - Files          │ │ - Merging        │ │ - Agent Workflow    │
└──────────────────┘ └──────────────────┘ └──────────────────────┘
          ▼                    ▼                      ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Storage Layer                               │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐ │
│  │   Document   │  │    Vector    │  │    Metadata          │ │
│  │     DB       │  │      DB      │  │    Storage           │ │
│  │  (SQLite)    │  │  (ChromaDB)  │  │                      │ │
│  └──────────────┘  └──────────────┘  └──────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
          ▼                                          ▼
┌──────────────────────────────────┐  ┌──────────────────────────┐
│     LLM Integration Layer        │  │   Monitoring & Metrics   │
│  - Embedding Generation          │  │  - System Health         │
│  - VLM (Vision-Language Model)   │  │  - Performance Stats     │
│  - Multiple Provider Support     │  │  - Error Tracking        │
└──────────────────────────────────┘  └──────────────────────────┘
```

## 📦 Core Components

### 1. Server Layer (`opencontext/server/`)

**Responsibilities:**
- HTTP request handling via FastAPI
- WebSocket connections for real-time updates
- API route management
- Static file serving
- Authentication and middleware

**Key Files:**
- `api.py` - Main router configuration
- `opencontext.py` - OpenContext main class
- `routes/` - API endpoint definitions
  - `health.py` - Health check endpoints
  - `context.py` - Context CRUD operations
  - `vaults.py` - Document management
  - `agent_chat.py` - AI chat interface
  - `completions.py` - Smart completion API
  - `screenshots.py` - Screenshot management
  - `monitoring.py` - System monitoring
  - `settings.py` - Configuration endpoints

### 2. Manager Layer (`opencontext/managers/`)

Coordinates between layers and manages component lifecycle.

#### CaptureManager (`capture_manager.py`)
- Registers and manages capture components
- Coordinates multiple capture sources
- Handles capture callbacks and statistics
- Provides unified capture interface

**Key Methods:**
```python
def register_component(name: str, component: ICaptureComponent) -> bool
def start_component(component_name: str) -> bool
def stop_component(component_name: str, graceful: bool) -> bool
def capture(component_name: str) -> List[RawContextProperties]
```

#### ProcessorManager (`processor_manager.py`)
- Manages processing pipeline
- Routes context data to appropriate processors
- Handles batch processing
- Manages periodic tasks (e.g., memory compression)

**Key Methods:**
```python
def register_processor(processor: IContextProcessor) -> bool
def process(initial_input: RawContextProperties) -> bool
def batch_process(inputs: List[RawContextProperties]) -> Dict
```

#### ConsumptionManager (`consumption_manager.py`)
- Manages content generation
- Coordinates AI workflows
- Handles scheduled tasks (summaries, todos, tips)
- Manages completion services

#### EventManager (`event_manager.py`)
- Event-driven coordination
- Pub/sub messaging between components
- Asynchronous event handling

### 3. Context Capture Layer (`opencontext/context_capture/`)

Responsible for collecting context from various sources.

**Components:**

#### Screenshot Capture (`screenshot.py`)
- Periodic screen capture
- Multi-monitor support
- Configurable capture intervals
- Image compression and storage

#### Document Monitor (`vault_document_monitor.py`)
- Watches document changes
- Detects new/modified files
- Triggers processing pipeline

#### Base Interface (`base.py`)
```python
class ICaptureComponent(ABC):
    @abstractmethod
    def initialize(config: Dict) -> bool
    
    @abstractmethod
    def start() -> bool
    
    @abstractmethod
    def stop(graceful: bool) -> bool
    
    @abstractmethod
    def capture() -> List[RawContextProperties]
    
    @abstractmethod
    def set_callback(callback: Callable) -> None
```

### 4. Context Processing Layer (`opencontext/context_processing/`)

Transforms raw context into structured, searchable data.

**Sub-components:**

#### Chunker (`chunker/`)
- Splits documents into manageable chunks
- Preserves semantic boundaries
- Handles multiple document formats
- Configurable chunk sizes

**Strategies:**
- `fixed_chunker.py` - Fixed-size chunks
- `semantic_chunker.py` - Semantic boundary detection
- `hybrid_chunker.py` - Combines multiple strategies

#### Processor (`processor/`)
- Document processing pipeline
- Entity extraction
- Metadata generation
- Embedding generation

**Processors:**
- `screenshot_processor.py` - Analyzes screenshots with VLM
- `document_processor.py` - Processes text documents
- `entity_processor.py` - Extracts entities and relationships

#### Merger (`merger/`)
- Combines related contexts
- Deduplicates information
- Compresses memory
- Maintains semantic relationships

### 5. Context Consumption Layer (`opencontext/context_consumption/`)

Uses processed context to generate value.

#### Generation (`generation/`)
- Daily/weekly summaries
- Todo extraction
- Tips and insights
- Activity reports

**Generators:**
- `activity_generator.py` - Activity summaries
- `todo_generator.py` - Todo extraction
- `tip_generator.py` - Insight generation
- `summary_generator.py` - Periodic summaries

#### Completion (`completion/`)
- Smart text completion
- Context-aware suggestions
- Real-time completion service

#### Context Agent (`context_agent/`)
- LangGraph-based workflows
- Multi-step reasoning
- Tool integration
- Conversation management

### 6. Storage Layer (`opencontext/storage/`)

Multi-backend storage supporting different data types.

**Architecture:**
```
UnifiedStorage (unified_storage.py)
    ├── IDocumentStorageBackend
    │   └── SQLiteBackend (sqlite_backend.py)
    └── IVectorStorageBackend
        ├── ChromaDBBackend (chromadb_backend.py)
        └── VikingDBBackend (vikingdb_backend.py)
```

**Key Features:**
- Unified API across backends
- Automatic routing by data type
- Vector similarity search
- Metadata filtering
- Batch operations

### 7. LLM Integration Layer (`opencontext/llm/`)

Manages interactions with language models.

**Components:**

#### LLMClient (`llm_client.py`)
- Base client for LLM interactions
- Streaming support
- Error handling and retry logic
- Token counting

#### GlobalEmbeddingClient (`global_embedding_client.py`)
- Singleton embedding service
- Multi-provider support (OpenAI, Doubao)
- Batch embedding generation
- Caching optimization

#### GlobalVLMClient (`global_vlm_client.py`)
- Vision-Language Model client
- Image analysis
- Multi-modal understanding
- Screenshot interpretation

**Provider Support:**
- OpenAI (GPT, DALL-E)
- Doubao (ByteDance models)
- Extensible for new providers

### 8. Tools System (`opencontext/tools/`)

Provides capabilities for AI agents.

**Tool Categories:**

#### Retrieval Tools (`retrieval_tools/`)
- Context search
- Similarity queries
- Filtered retrieval

#### Operation Tools (`operation_tools/`)
- Document creation
- Content modification
- System operations

#### Profile Tools (`profile_tools/`)
- User preferences
- System configuration
- Profile management

### 9. Models (`opencontext/models/`)

Core data models and enumerations.

**Key Models:**

#### RawContextProperties (`context.py`)
```python
class RawContextProperties(BaseModel):
    content_format: ContentFormat
    source: ContextSource
    create_time: datetime
    object_id: str
    content_path: Optional[str]
    content_text: Optional[str]
    additional_info: Optional[Dict]
```

#### ProcessedContext (`context.py`)
```python
class ProcessedContext(BaseModel):
    doc_id: str
    context_type: ContextType
    title: str
    summary: str
    content: str
    chunks: List[Chunk]
    extracted_data: ExtractedData
    create_time: datetime
    update_time: datetime
```

#### Enumerations (`enums.py`)
- `ContentFormat`: TEXT, IMAGE, VIDEO
- `ContextSource`: SCREENSHOT, FILE, VAULT
- `ContextType`: ACTIVITY, DOCUMENT, NOTE, etc.

### 10. Configuration (`opencontext/config/`)

Centralized configuration management.

**Components:**
- `config_manager.py` - Configuration loading and validation
- `prompt_manager.py` - Prompt template management
- `global_config.py` - Global configuration singleton

### 11. Monitoring (`opencontext/monitoring/`)

System health and performance monitoring.

**Features:**
- Component health checks
- Performance metrics
- Error tracking
- Resource utilization

## 🔄 Data Flow

### 1. Context Capture Flow
```
User Activity → Capture Component → RawContextProperties → ProcessorManager
```

### 2. Processing Flow
```
RawContextProperties → Processor → Chunker → Entity Extractor → ProcessedContext → Storage
```

### 3. Consumption Flow
```
User Query → Retrieval → Context Selection → LLM Processing → Response/Generation
```

### 4. Real-time Update Flow
```
Context Change → Event → WebSocket → Frontend Update
```

## 🔌 Extension Points

MineContext is designed for extensibility:

1. **New Capture Sources**: Implement `ICaptureComponent` interface
2. **Custom Processors**: Extend `IContextProcessor` interface
3. **Storage Backends**: Implement storage backend interfaces
4. **LLM Providers**: Add provider in LLM integration layer
5. **Generation Types**: Create new generators in consumption layer
6. **Tools**: Add new tools for agent capabilities

## 🎯 Design Patterns

**Patterns Used:**

1. **Singleton Pattern**: Global configuration and clients
2. **Strategy Pattern**: Chunking strategies, processors
3. **Observer Pattern**: Event-driven coordination
4. **Factory Pattern**: Storage backend creation
5. **Pipeline Pattern**: Processing pipeline
6. **Repository Pattern**: Storage abstraction

## 📊 Component Dependencies

```
CLI → OpenContext → Managers → {Capture, Processing, Consumption}
                              ↓
                          Storage ← LLM Integration
```

**Minimal Dependencies:**
- Capture components are independent
- Processors depend only on interfaces
- Storage layer is abstracted
- LLM integration is modular

## 🔒 Security Considerations

1. **Local-First**: All data stored locally
2. **API Key Protection**: Secure key storage
3. **Authentication**: Middleware for API protection
4. **Sandboxing**: Isolated component execution
5. **Input Validation**: All inputs validated

## ⚡ Performance Optimizations

1. **Async Processing**: Non-blocking I/O operations
2. **Batch Operations**: Efficient bulk processing
3. **Caching**: LLM response and embedding caching
4. **Lazy Loading**: On-demand component initialization
5. **Connection Pooling**: Efficient database connections
6. **Parallel Processing**: Multi-threaded processing

## 📚 Further Reading

- [Data Flow & Workflow](./04-data-flow-workflow.md) - Detailed processing pipeline
- [Configuration Guide](./05-configuration-guide.md) - Configuration options
- [API Reference](./06-api-reference.md) - Complete API documentation
- [Development Guide](./12-development-guide.md) - Contributing and extending
