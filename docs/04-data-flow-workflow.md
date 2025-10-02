# Data Flow & Workflow

This document details how data flows through MineContext, from capture to consumption.

## 🔄 Complete Workflow Overview

```
┌─────────────┐
│   Capture   │  User Activity (Screenshot, Document, etc.)
└─────┬───────┘
      │
      ▼
┌─────────────────────────────┐
│  Raw Context Properties     │  Store metadata and content reference
│  - source: SCREENSHOT/FILE  │
│  - content_path/text        │
│  - timestamp                │
│  - metadata                 │
└─────┬───────────────────────┘
      │
      ▼
┌─────────────────────────────┐
│   Processor Manager         │  Route to appropriate processor
└─────┬───────────────────────┘
      │
      ├─── Screenshot? ──────────┐
      │                          ▼
      │                    ┌─────────────────┐
      │                    │ VLM Analysis    │
      │                    │ - Extract text  │
      │                    │ - Describe scene│
      │                    └────┬────────────┘
      │                         │
      └─── Document? ───────────┤
                                ▼
                    ┌───────────────────────┐
                    │  Document Processing  │
                    │  - Parse content      │
                    │  - Extract metadata   │
                    └───────┬───────────────┘
                            │
                            ▼
                    ┌───────────────────────┐
                    │    Chunking           │
                    │  - Split into pieces  │
                    │  - Preserve semantics │
                    │  - Add metadata       │
                    └───────┬───────────────┘
                            │
                            ▼
                    ┌───────────────────────┐
                    │  Entity Extraction    │
                    │  - Extract keywords   │
                    │  - Identify entities  │
                    │  - Generate tags      │
                    └───────┬───────────────┘
                            │
                            ▼
                    ┌───────────────────────┐
                    │  Context Merging      │
                    │  - Find similar       │
                    │  - Merge related      │
                    │  - Deduplicate        │
                    └───────┬───────────────┘
                            │
                            ▼
                    ┌───────────────────────┐
                    │  Embedding Generation │
                    │  - Generate vectors   │
                    │  - Batch processing   │
                    └───────┬───────────────┘
                            │
                            ▼
                    ┌───────────────────────┐
                    │  Processed Context    │
                    │  - Structured data    │
                    │  - Embeddings         │
                    │  - Metadata           │
                    └───────┬───────────────┘
                            │
                            ▼
                    ┌───────────────────────┐
                    │    Storage Layer      │
                    │  - Document DB        │
                    │  - Vector DB          │
                    └───────┬───────────────┘
                            │
                            ▼
                    ┌───────────────────────┐
                    │  Context Consumption  │
                    │  - Retrieval          │
                    │  - Generation         │
                    │  - Completion         │
                    └───────────────────────┘
```

## 📥 Context Capture Workflow

### Screenshot Capture Flow

```python
# 1. Periodic capture triggered
ScreenshotCapture.capture()
    │
    ├─ Take screenshot
    ├─ Save to file
    ├─ Get window/app info
    └─ Create RawContextProperties
        {
            "source": ContextSource.SCREENSHOT,
            "content_format": ContentFormat.IMAGE,
            "content_path": "/path/to/screenshot.png",
            "create_time": "2025-01-01T12:00:00",
            "additional_info": {
                "window": "Browser",
                "app": "Chrome"
            }
        }
    │
    ▼
Callback → CaptureManager._on_component_capture()
    │
    ▼
OpenContext._handle_captured_context()
    │
    ▼
ProcessorManager.process()
```

### Document Upload Flow

```python
# 1. User uploads document via API
POST /api/vaults/create
    {
        "title": "My Document",
        "content": "Document text...",
        "document_type": "note"
    }
    │
    ▼
# 2. Create RawContextProperties
RawContextProperties(
    source=ContextSource.VAULT,
    content_format=ContentFormat.TEXT,
    content_text=content,
    additional_info={"title": title}
)
    │
    ▼
# 3. Process through pipeline
ProcessorManager.process()
```

## 🔧 Processing Pipeline Details

### Stage 1: Initial Processing

**Screenshot Processing:**
```python
ScreenshotProcessor.process(raw_context)
    │
    ├─ Load image from content_path
    ├─ Call VLM to analyze
    │   {
    │       "description": "Screenshot shows...",
    │       "text_content": "Extracted text",
    │       "context_type": "ACTIVITY"
    │   }
    │
    └─ Create initial ProcessedContext
        {
            "title": "Activity at 12:00",
            "content": description + text_content,
            "context_type": ContextType.ACTIVITY
        }
```

**Document Processing:**
```python
DocumentProcessor.process(raw_context)
    │
    ├─ Parse content (text/markdown/etc)
    ├─ Extract title and metadata
    ├─ Initial structuring
    │
    └─ Create ProcessedContext
        {
            "title": extracted_title,
            "content": parsed_content,
            "context_type": ContextType.DOCUMENT
        }
```

### Stage 2: Chunking

```python
ChunkerService.chunk(processed_context)
    │
    ├─ Select chunking strategy
    │   ├─ Fixed size (for uniform chunks)
    │   ├─ Semantic (for meaningful boundaries)
    │   └─ Hybrid (combination)
    │
    ├─ Split content into chunks
    │   Chunk {
    │       text: "Section of content...",
    │       chunk_index: 0,
    │       start_position: 0,
    │       end_position: 512,
    │       metadata: {...}
    │   }
    │
    └─ Add to ProcessedContext.chunks
```

**Chunking Strategies:**

1. **Fixed Size Chunking:**
   - Fixed character/token count
   - Configurable overlap
   - Fast and simple

2. **Semantic Chunking:**
   - Respects paragraph boundaries
   - Identifies topic changes
   - Better for long documents

3. **Hybrid Chunking:**
   - Combines fixed and semantic
   - Optimal balance

### Stage 3: Entity Extraction

```python
EntityProcessor.extract(processed_context)
    │
    ├─ Analyze content with LLM
    │   Prompt: "Extract key information from: {content}"
    │
    ├─ Parse LLM response
    │   {
    │       "keywords": ["AI", "context", "capture"],
    │       "entities": ["MineContext", "OpenAI"],
    │       "tags": ["technology", "AI"],
    │       "summary": "Brief summary...",
    │       "context_type": "DOCUMENT",
    │       "importance": 7
    │   }
    │
    └─ Update ProcessedContext.extracted_data
```

### Stage 4: Context Merging

```python
MergerProcessor.merge(processed_context)
    │
    ├─ Find similar contexts
    │   ├─ Query vector DB for similar embeddings
    │   ├─ Check time proximity
    │   └─ Match context types
    │
    ├─ Merge related contexts
    │   ├─ Combine content
    │   ├─ Merge keywords/entities
    │   ├─ Update relationships
    │   └─ Track merge history
    │
    └─ Return merged context or original
```

**Merge Rules:**
- Screenshots within 15 minutes → Activity session
- Related documents → Document collection
- Similar content → Deduplicated entry

### Stage 5: Embedding Generation

```python
EmbeddingService.generate_embeddings(processed_context)
    │
    ├─ For each chunk:
    │   ├─ Prepare text for embedding
    │   ├─ Call embedding model
    │   └─ Store vector
    │
    └─ Update ProcessedContext.vectorize
        {
            "title_embedding": [0.1, 0.2, ...],
            "summary_embedding": [0.3, 0.4, ...],
            "chunk_embeddings": [
                [0.5, 0.6, ...],
                [0.7, 0.8, ...]
            ]
        }
```

### Stage 6: Storage

```python
UnifiedStorage.insert_processed_context(processed_context)
    │
    ├─ Store in Document DB (SQLite)
    │   ├─ Insert metadata
    │   ├─ Insert content
    │   ├─ Insert chunks
    │   └─ Insert relationships
    │
    └─ Store in Vector DB (ChromaDB)
        ├─ Insert title embedding
        ├─ Insert summary embedding
        └─ Insert chunk embeddings
```

## 🎯 Context Consumption Workflows

### Retrieval Workflow

```python
# User query
query = "Tell me about my AI projects"

# 1. Generate query embedding
query_embedding = embedding_client.embed(query)

# 2. Search vector database
similar_contexts = vector_db.search(
    embedding=query_embedding,
    top_k=10,
    filters={"context_type": "DOCUMENT"}
)

# 3. Fetch full contexts from document DB
full_contexts = [
    document_db.get(ctx.doc_id)
    for ctx in similar_contexts
]

# 4. Rank and filter
ranked = rank_by_relevance(full_contexts, query)

# 5. Return to user or LLM
return ranked[:5]
```

### Content Generation Workflow

```python
# Daily summary generation
DailySummaryGenerator.generate()
    │
    ├─ Get contexts from last 24 hours
    │   contexts = storage.query(
    │       start_time=yesterday,
    │       end_time=now
    │   )
    │
    ├─ Retrieve relevant contexts
    │   retrieved = search_contexts(
    │       query="daily activities",
    │       contexts=contexts
    │   )
    │
    ├─ Generate summary with LLM
    │   summary = llm.complete(
    │       prompt=f"Summarize: {retrieved}",
    │       max_tokens=500
    │   )
    │
    └─ Store and display
        storage.insert_vaults(
            title="Daily Summary - 2025-01-01",
            content=summary,
            document_type="summary"
        )
```

### Smart Completion Workflow

```python
# User typing in editor
CompletionService.get_completion(
    text="I need to finish the",
    cursor_position=20
)
    │
    ├─ Extract context from current document
    ├─ Get recent user activity
    │
    ├─ Retrieve relevant contexts
    │   contexts = search_contexts(
    │       query=text[:cursor_position],
    │       top_k=5
    │   )
    │
    ├─ Generate completion
    │   completion = llm.complete(
    │       prompt=f"""Given context: {contexts}
    │                  Continue: {text}""",
    │       max_tokens=50
    │   )
    │
    └─ Return suggestions
        {
            "completions": [
                "project by Friday",
                "report by end of week",
                "presentation tomorrow"
            ]
        }
```

### Agent Workflow (LangGraph)

```python
# User: "Create a todo list from my recent screenshots"

AgentWorkflow.execute(user_message)
    │
    ├─ Parse intent
    │   Intent: CREATE_TODO
    │   Source: SCREENSHOTS
    │   Timeframe: RECENT
    │
    ├─ Plan steps
    │   1. Retrieve recent screenshots
    │   2. Extract tasks
    │   3. Create todo items
    │   4. Confirm with user
    │
    ├─ Execute steps
    │   Step 1: Retrieve
    │   contexts = retrieval_tool.search(
    │       context_type=ACTIVITY,
    │       time_range=last_24h
    │   )
    │   
    │   Step 2: Extract
    │   todos = llm.extract_todos(contexts)
    │   
    │   Step 3: Create (after confirmation)
    │   for todo in todos:
    │       storage.insert_todo(todo)
    │
    └─ Return result
        "Created 5 todo items from recent activities"
```

## 🔄 Event-Driven Updates

### Real-time Update Flow

```python
# 1. Context changes in storage
storage.insert_processed_context(context)
    │
    ▼
# 2. Emit event
event_manager.emit(
    event="context_added",
    data={"doc_id": context.doc_id}
)
    │
    ▼
# 3. Event handler
@event_manager.on("context_added")
def handle_context_added(data):
    # Notify WebSocket clients
    websocket_manager.broadcast({
        "type": "context_update",
        "doc_id": data["doc_id"]
    })
    │
    ▼
# 4. Frontend receives update
websocket.onmessage = (event) => {
    if (event.type === "context_update") {
        refreshContextList()
    }
}
```

## 📊 Data State Transitions

```
Raw Context State Machine:
┌─────────┐
│ Created │
└────┬────┘
     │
     ▼
┌─────────────┐
│ Queued      │
└─────┬───────┘
      │
      ▼
┌─────────────┐
│ Processing  │
└─────┬───────┘
      │
      ├──Success──▶ ┌───────────┐
      │             │ Processed │
      │             └───────────┘
      │
      └──Error────▶ ┌───────────┐
                    │  Failed   │
                    └───────────┘
```

```
Processed Context Lifecycle:
┌─────────┐
│  New    │
└────┬────┘
     │
     ▼
┌──────────┐
│  Active  │ ◀─── Can be updated
└────┬─────┘
     │
     ├─── Time ───▶ ┌──────────┐
     │              │ Archived │
     │              └──────────┘
     │
     └─── User ───▶ ┌──────────┐
                    │ Deleted  │
                    └──────────┘
```

## ⏱️ Timing and Scheduling

### Periodic Tasks

1. **Screenshot Capture**: Every 5 seconds (configurable)
2. **Memory Compression**: Every 30 minutes
3. **Daily Summary**: Every day at 8 PM
4. **Weekly Summary**: Every Sunday at 8 PM
5. **Health Check**: Every minute

### Async vs Sync Operations

**Synchronous:**
- API request handling
- Storage queries
- Configuration loading

**Asynchronous:**
- Screenshot capture
- LLM API calls
- Embedding generation
- Background processing
- Event notification

## 🚀 Performance Considerations

### Batch Processing

- Process multiple contexts together
- Batch embedding generation
- Bulk storage operations

### Caching

- LLM response caching
- Embedding caching
- Query result caching

### Parallel Processing

- Multi-threaded capture
- Concurrent LLM calls
- Parallel chunk processing

## 🔍 Error Handling

### Retry Logic

```python
@retry(max_attempts=3, backoff=2)
def call_llm(prompt):
    return llm_client.complete(prompt)
```

### Fallback Strategies

1. LLM unavailable → Use cached results
2. Storage error → Queue for later
3. Processing failure → Log and continue

### Error Recovery

- Automatic retry for transient errors
- Manual intervention for persistent errors
- Detailed error logging

## 📚 Next Steps

- [Storage System](./07-storage-system.md) - Deep dive into storage
- [Context Processing](./10-context-processing.md) - Processing details
- [API Reference](./06-api-reference.md) - API endpoints
