# Context Processing Documentation

This document details how MineContext processes raw context data into structured, searchable information.

## 🔧 Processing Pipeline Overview

```
Raw Context → Processor → Chunker → Entity Extractor → Merger → Embeddings → Storage
```

**Detailed Flow:**

```
┌─────────────────────────┐
│   Raw Context Input     │
│ (Screenshot, Document)  │
└────────────┬────────────┘
             │
             ▼
┌─────────────────────────┐
│   Initial Processing    │
│ - Screenshot: VLM       │
│ - Document: Parse       │
└────────────┬────────────┘
             │
             ▼
┌─────────────────────────┐
│   Content Chunking      │
│ - Split into segments   │
│ - Preserve semantics    │
└────────────┬────────────┘
             │
             ▼
┌─────────────────────────┐
│  Entity Extraction      │
│ - Keywords              │
│ - Entities              │
│ - Tags                  │
└────────────┬────────────┘
             │
             ▼
┌─────────────────────────┐
│   Context Merging       │
│ - Find related          │
│ - Combine similar       │
│ - Deduplicate           │
└────────────┬────────────┘
             │
             ▼
┌─────────────────────────┐
│  Embedding Generation   │
│ - Title embedding       │
│ - Summary embedding     │
│ - Chunk embeddings      │
└────────────┬────────────┘
             │
             ▼
┌─────────────────────────┐
│  Processed Context      │
│ (Ready for storage)     │
└─────────────────────────┘
```

## 📦 Processing Components

### 1. Processor Manager (`processor_manager.py`)

Coordinates the processing pipeline.

**Key Responsibilities:**
- Route contexts to appropriate processors
- Manage processing chains
- Handle batch processing
- Coordinate periodic tasks

**Routing Table:**

```python
_routing_table = {
    ContextSource.SCREENSHOT: "screenshot_processor",
    ContextSource.FILE: "document_processor",
    ContextSource.VAULT: "document_processor",
}
```

**Usage:**

```python
manager = ContextProcessorManager()

# Register processors
manager.register_processor(screenshot_processor)
manager.register_processor(document_processor)
manager.register_processor(entity_processor)
manager.set_merger(merger_processor)

# Process single context
success = manager.process(raw_context)

# Batch process
results = manager.batch_process(raw_contexts)
```

### 2. Screenshot Processor (`screenshot_processor.py`)

Processes screenshots using Vision-Language Model.

**Process:**

```python
class ScreenshotProcessor(IContextProcessor):
    def process(self, context: RawContextProperties) -> bool:
        """
        Process screenshot context.
        
        Steps:
        1. Load image from path
        2. Analyze with VLM
        3. Extract text and description
        4. Determine context type
        5. Create ProcessedContext
        6. Store
        """
        # Load image
        image_path = context.content_path
        
        # Analyze with VLM
        vlm_client = GlobalVLMClient.get_instance()
        analysis = vlm_client.analyze_image(
            image_path,
            prompt=self._get_analysis_prompt()
        )
        
        # Parse analysis
        description = analysis.get("description", "")
        extracted_text = analysis.get("extracted_text", "")
        context_type = self._determine_context_type(analysis)
        
        # Create processed context
        processed = ProcessedContext(
            doc_id=context.object_id,
            context_type=context_type,
            title=self._generate_title(context, analysis),
            summary=description[:200],
            content=f"{description}\n\nExtracted Text:\n{extracted_text}",
            source=context.source,
            create_time=context.create_time,
            update_time=datetime.now(),
            additional_metadata={
                "window": context.additional_info.get("window"),
                "app": context.additional_info.get("app"),
                "image_path": image_path
            }
        )
        
        # Continue to chunking
        self._process_chunks(processed)
        
        # Store
        storage = get_storage()
        return storage.insert_processed_context(processed)
```

**Analysis Prompt:**

```python
def _get_analysis_prompt(self) -> str:
    """Get VLM analysis prompt."""
    return """Analyze this screenshot and provide:

1. DESCRIPTION: A detailed description of what's happening in the image (2-3 sentences)

2. CONTEXT_TYPE: The type of activity (choose one):
   - CODING: Programming/development work
   - WRITING: Document editing, writing
   - BROWSING: Web browsing, research
   - MEETING: Video call, presentation
   - COMMUNICATION: Email, chat, messaging
   - ENTERTAINMENT: Video, music, games
   - DESIGN: UI/UX design, graphics
   - OTHER: Other activities

3. EXTRACTED_TEXT: Any visible text in the image (be comprehensive)

4. KEY_ENTITIES: Important entities mentioned (people, projects, tools, technologies)

5. MAIN_ACTIVITY: Single-phrase summary of main activity

Format response as JSON:
{
  "description": "...",
  "context_type": "...",
  "extracted_text": "...",
  "key_entities": ["...", "..."],
  "main_activity": "..."
}
"""
```

### 3. Document Processor (`document_processor.py`)

Processes text documents.

**Process:**

```python
class DocumentProcessor(IContextProcessor):
    def process(self, context: RawContextProperties) -> bool:
        """Process document context."""
        
        # Get content
        if context.content_text:
            content = context.content_text
        elif context.content_path:
            content = self._read_file(context.content_path)
        else:
            return False
        
        # Parse content
        parsed = self._parse_content(content, context.content_path)
        
        # Extract metadata
        title = self._extract_title(parsed, context)
        summary = self._generate_summary(parsed)
        
        # Create processed context
        processed = ProcessedContext(
            doc_id=context.object_id,
            context_type=ContextType.DOCUMENT,
            title=title,
            summary=summary,
            content=parsed["text"],
            source=context.source,
            create_time=context.create_time,
            update_time=datetime.now()
        )
        
        # Continue to chunking and entity extraction
        self._process_chunks(processed)
        
        # Store
        storage = get_storage()
        return storage.insert_processed_context(processed)
    
    def _parse_content(self, content: str, filepath: Optional[str]) -> Dict:
        """Parse content based on file type."""
        if not filepath:
            return {"text": content, "format": "text"}
        
        ext = Path(filepath).suffix.lower()
        
        if ext == ".md":
            return self._parse_markdown(content)
        elif ext == ".pdf":
            return self._parse_pdf(filepath)
        elif ext == ".docx":
            return self._parse_docx(filepath)
        else:
            return {"text": content, "format": "text"}
    
    def _parse_markdown(self, content: str) -> Dict:
        """Parse Markdown content."""
        import markdown
        
        # Extract frontmatter if present
        frontmatter = self._extract_frontmatter(content)
        
        # Parse markdown to HTML (for structure)
        html = markdown.markdown(content, extensions=[
            'markdown.extensions.meta',
            'markdown.extensions.tables',
            'markdown.extensions.fenced_code'
        ])
        
        return {
            "text": content,
            "html": html,
            "format": "markdown",
            "metadata": frontmatter
        }
```

### 4. Chunking System (`chunker/`)

Splits content into manageable pieces.

**Chunking Strategies:**

#### Fixed Chunker (`fixed_chunker.py`)

```python
class FixedChunker:
    def __init__(self, chunk_size: int = 512, overlap: int = 50):
        self.chunk_size = chunk_size
        self.overlap = overlap
    
    def chunk(self, text: str) -> List[Chunk]:
        """Split text into fixed-size chunks with overlap."""
        chunks = []
        start = 0
        chunk_index = 0
        
        while start < len(text):
            end = start + self.chunk_size
            chunk_text = text[start:end]
            
            chunks.append(Chunk(
                text=chunk_text,
                chunk_index=chunk_index,
                start_position=start,
                end_position=end
            ))
            
            chunk_index += 1
            start = end - self.overlap  # Move back by overlap
        
        return chunks
```

#### Semantic Chunker (`semantic_chunker.py`)

```python
class SemanticChunker:
    def __init__(self, min_size: int = 100, max_size: int = 1000):
        self.min_size = min_size
        self.max_size = max_size
    
    def chunk(self, text: str) -> List[Chunk]:
        """Split text at semantic boundaries."""
        # Split by paragraphs
        paragraphs = text.split('\n\n')
        
        chunks = []
        current_chunk = []
        current_size = 0
        chunk_index = 0
        
        for para in paragraphs:
            para_size = len(para)
            
            # If adding this paragraph would exceed max_size
            if current_size + para_size > self.max_size and current_chunk:
                # Create chunk from current buffer
                chunk_text = '\n\n'.join(current_chunk)
                chunks.append(Chunk(
                    text=chunk_text,
                    chunk_index=chunk_index,
                    semantic_type="paragraph_group"
                ))
                chunk_index += 1
                current_chunk = []
                current_size = 0
            
            current_chunk.append(para)
            current_size += para_size
        
        # Add remaining
        if current_chunk:
            chunk_text = '\n\n'.join(current_chunk)
            chunks.append(Chunk(
                text=chunk_text,
                chunk_index=chunk_index
            ))
        
        return chunks
```

#### Hybrid Chunker (`hybrid_chunker.py`)

```python
class HybridChunker:
    def __init__(self, target_size: int = 512, tolerance: int = 100):
        self.target_size = target_size
        self.tolerance = tolerance
        self.semantic = SemanticChunker()
        self.fixed = FixedChunker(target_size)
    
    def chunk(self, text: str) -> List[Chunk]:
        """
        Use semantic chunking where possible,
        fall back to fixed for long paragraphs.
        """
        semantic_chunks = self.semantic.chunk(text)
        
        final_chunks = []
        for schunk in semantic_chunks:
            # If chunk is within acceptable range, keep it
            if abs(len(schunk.text) - self.target_size) <= self.tolerance:
                final_chunks.append(schunk)
            # If too long, split with fixed chunker
            elif len(schunk.text) > self.target_size + self.tolerance:
                sub_chunks = self.fixed.chunk(schunk.text)
                final_chunks.extend(sub_chunks)
            # If too short, try to merge with next
            else:
                final_chunks.append(schunk)
        
        return final_chunks
```

### 5. Entity Processor (`entity_processor.py`)

Extracts structured information from content.

```python
class EntityProcessor(IContextProcessor):
    def process(self, context: ProcessedContext) -> bool:
        """Extract entities from processed context."""
        
        # Prepare content for extraction
        content = self._prepare_content(context)
        
        # Call LLM for extraction
        llm_client = LLMClient.get_instance()
        
        prompt = self._build_extraction_prompt(content)
        response = llm_client.complete(prompt, temperature=0.1)
        
        # Parse response
        try:
            extracted = json.loads(response)
        except json.JSONDecodeError:
            extracted = self._parse_non_json_response(response)
        
        # Update context with extracted data
        context.extracted_data = ExtractedData(
            title=context.title,
            summary=extracted.get("summary", context.summary),
            keywords=extracted.get("keywords", []),
            entities=extracted.get("entities", []),
            tags=extracted.get("tags", []),
            context_type=context.context_type,
            confidence=extracted.get("confidence", 0),
            importance=extracted.get("importance", 5)
        )
        
        # Update storage
        storage = get_storage()
        return storage.update_processed_context(context.doc_id, context)
    
    def _build_extraction_prompt(self, content: str) -> str:
        """Build prompt for entity extraction."""
        return f"""Extract structured information from this content:

Content:
{content[:2000]}  # Truncate if too long

Extract:
1. Keywords: 5-10 most important keywords or phrases
2. Entities: Named entities (people, organizations, projects, technologies)
3. Tags: 3-5 category tags (e.g., "work", "AI", "coding")
4. Summary: 1-2 sentence summary (if different from title)
5. Importance: Rate 1-10 (how important/useful is this content)
6. Confidence: Rate 0.0-1.0 (how confident in the extraction)

Return as JSON:
{{
  "keywords": ["keyword1", "keyword2", ...],
  "entities": ["entity1", "entity2", ...],
  "tags": ["tag1", "tag2", ...],
  "summary": "Brief summary",
  "importance": 7,
  "confidence": 0.9
}}
"""
```

### 6. Merger Processor (`merger/`)

Combines related contexts and performs memory compression.

```python
class MergerProcessor:
    def __init__(self):
        self.embedding_client = GlobalEmbeddingClient.get_instance()
        self.storage = get_storage()
    
    def merge_related_contexts(self, context: ProcessedContext) -> ProcessedContext:
        """Find and merge related contexts."""
        
        # Search for similar contexts
        similar = self._find_similar_contexts(context)
        
        if not similar:
            return context
        
        # Determine if should merge
        if not self._should_merge(context, similar):
            return context
        
        # Merge contexts
        merged = self._merge_contexts(context, similar)
        
        # Update relationships
        self._update_relationships(merged, similar)
        
        return merged
    
    def _find_similar_contexts(
        self,
        context: ProcessedContext,
        time_window: int = 900  # 15 minutes
    ) -> List[ProcessedContext]:
        """Find contexts that might be related."""
        
        # Time-based search
        time_filter = {
            "create_time_min": context.create_time - timedelta(seconds=time_window),
            "create_time_max": context.create_time + timedelta(seconds=time_window)
        }
        
        # Get contexts in time window
        candidates = self.storage.query_contexts(
            filters=time_filter,
            limit=20
        )
        
        # Filter by similarity
        context_embedding = self.embedding_client.embed(context.summary)
        
        similar = []
        for candidate in candidates:
            # Skip self
            if candidate.doc_id == context.doc_id:
                continue
            
            # Compute similarity
            candidate_embedding = self.embedding_client.embed(candidate.summary)
            similarity = self._cosine_similarity(
                context_embedding,
                candidate_embedding
            )
            
            if similarity > 0.85:  # High similarity threshold
                similar.append(candidate)
        
        return similar
    
    def _merge_contexts(
        self,
        primary: ProcessedContext,
        others: List[ProcessedContext]
    ) -> ProcessedContext:
        """Merge multiple contexts into one."""
        
        # Combine content
        combined_content = [primary.content]
        combined_content.extend([c.content for c in others])
        
        # Merge chunks
        all_chunks = primary.chunks.copy()
        for other in others:
            all_chunks.extend(other.chunks)
        
        # Merge extracted data
        all_keywords = set(primary.extracted_data.keywords)
        all_entities = set(primary.extracted_data.entities)
        all_tags = set(primary.extracted_data.tags)
        
        for other in others:
            all_keywords.update(other.extracted_data.keywords)
            all_entities.update(other.extracted_data.entities)
            all_tags.update(other.extracted_data.tags)
        
        # Create merged context
        merged = ProcessedContext(
            doc_id=primary.doc_id,
            context_type=primary.context_type,
            title=primary.title,
            summary=self._generate_merged_summary(primary, others),
            content="\n\n".join(combined_content),
            chunks=all_chunks,
            extracted_data=ExtractedData(
                keywords=list(all_keywords)[:15],  # Top 15
                entities=list(all_entities)[:10],  # Top 10
                tags=list(all_tags)[:7],           # Top 7
                context_type=primary.context_type,
                importance=max(
                    primary.extracted_data.importance,
                    max([c.extracted_data.importance for c in others])
                )
            ),
            source=primary.source,
            create_time=primary.create_time,
            update_time=datetime.now()
        )
        
        return merged
    
    def periodic_memory_compression(self, interval_seconds: int):
        """
        Periodic task to compress old contexts.
        
        This helps manage storage and improve performance.
        """
        # Get contexts older than threshold
        threshold_time = datetime.now() - timedelta(seconds=interval_seconds)
        
        old_contexts = self.storage.query_contexts(
            filters={"create_time_max": threshold_time},
            limit=100
        )
        
        # Group related contexts
        groups = self._group_related_contexts(old_contexts)
        
        # Compress each group
        for group in groups:
            compressed = self._compress_context_group(group)
            
            # Store compressed version
            self.storage.insert_processed_context(compressed)
            
            # Mark originals as archived
            for ctx in group:
                self.storage.archive_context(ctx.doc_id)
```

## ⚙️ Configuration

```yaml
processing:
  # Chunking
  chunking:
    strategy: hybrid  # fixed, semantic, hybrid
    chunk_size: 512
    chunk_overlap: 50
    min_chunk_size: 100
    max_chunk_size: 1000
  
  # Entity Extraction
  entity_extraction:
    enabled: true
    min_confidence: 0.6
  
  # Merging
  merging:
    enabled: true
    time_window: 900  # seconds
    similarity_threshold: 0.85
  
  # Memory Compression
  compression:
    enabled: true
    interval: 1800  # 30 minutes
    min_age: 3600   # Only compress contexts older than 1 hour
```

## 🚀 Performance Optimization

### Parallel Processing

```python
def batch_process(self, contexts: List[RawContextProperties]) -> Dict:
    """Process multiple contexts in parallel."""
    with ThreadPoolExecutor(max_workers=5) as executor:
        futures = {
            executor.submit(self.process, ctx): ctx
            for ctx in contexts
        }
        
        results = {}
        for future in as_completed(futures):
            ctx = futures[future]
            try:
                result = future.result()
                results[ctx.object_id] = result
            except Exception as e:
                logger.error(f"Processing failed: {e}")
                results[ctx.object_id] = False
        
        return results
```

### Caching

```python
@lru_cache(maxsize=1000)
def extract_entities_cached(content_hash: str, content: str) -> ExtractedData:
    """Cache entity extraction results."""
    return extract_entities(content)
```

## 📚 Related Documentation

- [Architecture Overview](./03-architecture-overview.md)
- [Data Flow & Workflow](./04-data-flow-workflow.md)
- [LLM Integration](./08-llm-integration.md)
- [Context Capture](./09-context-capture.md)
