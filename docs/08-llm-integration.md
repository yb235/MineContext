# LLM Integration Documentation

This document details how MineContext integrates with Large Language Models (LLMs) and Vision-Language Models (VLMs).

## 🤖 LLM Architecture

MineContext uses three types of models:

```
┌─────────────────────────────────────────────────────┐
│             LLM Integration Layer                    │
└──────┬──────────────────┬──────────────────┬────────┘
       │                  │                  │
       ▼                  ▼                  ▼
┌──────────────┐  ┌──────────────┐  ┌─────────────────┐
│  Embedding   │  │     VLM      │  │   Text LLM      │
│   Client     │  │   Client     │  │    Client       │
│              │  │              │  │                 │
│ Text → Vec   │  │ Image → Text │  │ Text → Text     │
└──────────────┘  └──────────────┘  └─────────────────┘
       │                  │                  │
       ▼                  ▼                  ▼
┌──────────────────────────────────────────────────────┐
│          External API Providers                       │
│  - OpenAI (GPT-4, DALL-E, text-embedding-3)          │
│  - Doubao/ByteDance (doubao-pro, doubao-embedding)   │
│  - Custom endpoints (compatible APIs)                │
└──────────────────────────────────────────────────────┘
```

## 🔌 Components

### 1. Base LLM Client (`llm_client.py`)

The foundation for all LLM interactions.

**Key Features:**
- Streaming support
- Automatic retry with exponential backoff
- Token counting
- Error handling
- Rate limiting

**Basic Usage:**
```python
from opencontext.llm.llm_client import LLMClient

client = LLMClient(
    api_key="your-key",
    model="gpt-4",
    temperature=0.7
)

# Simple completion
response = client.complete("What is context engineering?")

# Streaming completion
for chunk in client.stream_complete("Tell me a story"):
    print(chunk, end="")
```

**Configuration:**
```python
client = LLMClient(
    api_key="key",
    model="gpt-4",
    base_url="https://api.openai.com/v1",  # Custom endpoint
    temperature=0.7,           # 0.0 = deterministic, 1.0 = creative
    max_tokens=1000,           # Response length limit
    timeout=30,                # Request timeout
    max_retries=3,             # Retry on failure
    retry_delay=1.0            # Initial retry delay
)
```

### 2. Embedding Client (`global_embedding_client.py`)

Generates vector embeddings for text.

**Singleton Pattern:**
```python
from opencontext.llm.global_embedding_client import GlobalEmbeddingClient

# Get singleton instance
client = GlobalEmbeddingClient.get_instance()

# Generate single embedding
embedding = client.embed("Machine learning is amazing")
# Returns: [0.1, 0.2, 0.3, ..., 0.9]  (1536 dimensions)

# Batch embeddings (more efficient)
texts = ["Text 1", "Text 2", "Text 3"]
embeddings = client.batch_embed(texts)
# Returns: [[...], [...], [...]]
```

**Configuration:**
```yaml
# config/config.yaml
embedding_model:
  provider: openai  # or doubao
  api_key: your-key
  model: text-embedding-3-large
  batch_size: 100  # Max texts per batch
```

**Supported Models:**

**OpenAI:**
- `text-embedding-3-large` (3072 dimensions, best quality)
- `text-embedding-3-small` (1536 dimensions, faster)
- `text-embedding-ada-002` (1536 dimensions, legacy)

**Doubao:**
- `doubao-embedding-large-text-240915` (1024 dimensions)

**Performance Tips:**
```python
# Use batch operations
texts = [chunk.text for chunk in chunks]
embeddings = client.batch_embed(texts, batch_size=50)

# Cache embeddings
from functools import lru_cache

@lru_cache(maxsize=1000)
def get_cached_embedding(text: str):
    return tuple(client.embed(text))
```

### 3. Vision-Language Model Client (`global_vlm_client.py`)

Analyzes images and generates descriptions.

**Usage:**
```python
from opencontext.llm.global_vlm_client import GlobalVLMClient

client = GlobalVLMClient.get_instance()

# Analyze image from path
result = client.analyze_image(
    image_path="/path/to/screenshot.png",
    prompt="Describe what's in this screenshot"
)

# Analyze with custom instructions
result = client.analyze_image(
    image_path="/path/to/screenshot.png",
    prompt="""Analyze this screenshot and extract:
    1. Main activity
    2. Visible applications
    3. Any text content
    4. Overall context
    """
)

# Result structure
{
    "description": "The screenshot shows...",
    "confidence": 0.95,
    "extracted_text": "Visible text from image"
}
```

**Configuration:**
```yaml
vlm_model:
  provider: openai  # or doubao
  api_key: your-key
  model: gpt-4-vision-preview
  max_tokens: 2000
  temperature: 0.7
```

**Supported Models:**

**OpenAI:**
- `gpt-4-vision-preview` (Best quality)
- `gpt-4-turbo-vision` (Faster)

**Doubao:**
- `doubao-seed-1-6-flash-250828`
- `doubao-vision-pro`

**Image Preprocessing:**
```python
# Resize large images
from opencontext.utils.image import resize_image

resized = resize_image(
    image_path,
    max_width=1920,
    max_height=1080,
    quality=85
)

# Analyze resized image
result = client.analyze_image(resized, prompt)
```

### 4. Text Generation Client

For content generation and chat.

**Usage:**
```python
from opencontext.llm.llm_client import LLMClient

client = LLMClient(
    api_key="key",
    model="gpt-4",
    temperature=0.7
)

# Generate summary
summary = client.complete(
    f"""Summarize the following content:
    
    {context_text}
    
    Summary:"""
)

# Chat-style interaction
messages = [
    {"role": "system", "content": "You are a helpful assistant."},
    {"role": "user", "content": "What did I work on today?"}
]
response = client.chat(messages)

# Streaming for real-time output
for token in client.stream_complete(prompt):
    print(token, end="", flush=True)
```

## 🔑 Provider Configuration

### OpenAI

```yaml
embedding_model:
  provider: openai
  api_key: sk-...
  model: text-embedding-3-large
  base_url: https://api.openai.com/v1  # Optional

vlm_model:
  provider: openai
  api_key: sk-...
  model: gpt-4-vision-preview
  
llm_model:
  provider: openai
  api_key: sk-...
  model: gpt-4-turbo-preview
  temperature: 0.7
  max_tokens: 2000
```

**Environment Variables:**
```bash
export OPENAI_API_KEY=sk-...
export OPENAI_BASE_URL=https://api.openai.com/v1
```

### Doubao (ByteDance)

```yaml
embedding_model:
  provider: doubao
  api_key: your-doubao-key
  model: doubao-embedding-large-text-240915
  base_url: https://ark.cn-beijing.volces.com/api/v3  # Optional

vlm_model:
  provider: doubao
  api_key: your-doubao-key
  model: doubao-seed-1-6-flash-250828

llm_model:
  provider: doubao
  api_key: your-doubao-key
  model: doubao-pro-32k-250115
```

### Custom Endpoints

For OpenAI-compatible APIs:

```yaml
embedding_model:
  provider: openai
  api_key: your-key
  model: custom-embedding-model
  base_url: https://your-custom-endpoint.com/v1
```

## 📊 Use Cases in MineContext

### 1. Screenshot Analysis

```python
# In screenshot_processor.py
def process_screenshot(screenshot_path: str) -> ProcessedContext:
    vlm_client = GlobalVLMClient.get_instance()
    
    # Analyze screenshot
    analysis = vlm_client.analyze_image(
        screenshot_path,
        prompt="""Analyze this screenshot:
        1. What is the main activity?
        2. What applications are visible?
        3. Extract any visible text
        4. What is the overall context (work, leisure, etc.)?
        """
    )
    
    # Create processed context
    return ProcessedContext(
        title=f"Activity at {timestamp}",
        content=analysis["description"],
        extracted_text=analysis.get("extracted_text", ""),
        context_type=determine_context_type(analysis)
    )
```

### 2. Entity Extraction

```python
# In entity_processor.py
def extract_entities(content: str) -> ExtractedData:
    llm_client = LLMClient.get_instance()
    
    prompt = f"""Extract key information from this text:
    
    Text: {content}
    
    Extract:
    - Keywords (5-10 important terms)
    - Entities (people, organizations, projects)
    - Tags (3-5 category tags)
    - Summary (1-2 sentences)
    
    Return as JSON.
    """
    
    response = llm_client.complete(prompt)
    extracted = json.loads(response)
    
    return ExtractedData(
        keywords=extracted["keywords"],
        entities=extracted["entities"],
        tags=extracted["tags"],
        summary=extracted["summary"]
    )
```

### 3. Content Generation

```python
# In summary_generator.py
def generate_daily_summary(contexts: List[ProcessedContext]) -> str:
    llm_client = LLMClient.get_instance()
    
    # Prepare context
    context_text = "\n\n".join([
        f"[{c.create_time}] {c.title}: {c.summary}"
        for c in contexts
    ])
    
    prompt = f"""Generate a daily summary based on these activities:
    
    {context_text}
    
    Create a concise summary highlighting:
    1. Main activities and accomplishments
    2. Key projects worked on
    3. Time allocation
    4. Notable insights
    
    Summary:"""
    
    return llm_client.complete(prompt, max_tokens=500)
```

### 4. Smart Completion

```python
# In completion_service.py
def get_completion(text: str, context: List[str]) -> List[str]:
    llm_client = LLMClient.get_instance()
    
    # Prepare context
    context_text = "\n".join(context[:5])  # Top 5 relevant contexts
    
    prompt = f"""Given this context:
    
    {context_text}
    
    Complete this text (provide 3 suggestions):
    {text}
    
    Completions:"""
    
    response = llm_client.complete(prompt, max_tokens=100)
    
    # Parse completions
    return parse_completions(response)
```

### 5. Todo Extraction

```python
# In todo_generator.py
def extract_todos(contexts: List[ProcessedContext]) -> List[Todo]:
    llm_client = LLMClient.get_instance()
    
    content = combine_contexts(contexts)
    
    prompt = f"""Extract actionable tasks from this content:
    
    {content}
    
    For each task, provide:
    - Title (brief description)
    - Description (details)
    - Priority (high/medium/low)
    - Estimated deadline (if mentioned)
    
    Return as JSON array.
    """
    
    response = llm_client.complete(prompt)
    todos_data = json.loads(response)
    
    return [Todo(**todo) for todo in todos_data]
```

## 🎛️ Advanced Features

### Temperature Control

**Temperature** controls randomness in responses:

- **0.0** - Deterministic, consistent
- **0.3** - Slightly creative, mostly focused
- **0.7** - Balanced creativity and consistency
- **1.0** - Very creative, diverse outputs

**Usage:**
```python
# For factual extraction (use low temperature)
client.complete(prompt, temperature=0.1)

# For creative generation (use higher temperature)
client.complete(prompt, temperature=0.8)
```

### Streaming

For real-time output:

```python
def stream_response(prompt: str):
    client = LLMClient.get_instance()
    
    for chunk in client.stream_complete(prompt):
        yield chunk
        # Update UI in real-time

# In FastAPI
@router.get("/stream")
async def stream_endpoint():
    return StreamingResponse(
        stream_response(prompt),
        media_type="text/event-stream"
    )
```

### Token Management

**Count tokens before sending:**
```python
import tiktoken

def count_tokens(text: str, model: str = "gpt-4") -> int:
    encoding = tiktoken.encoding_for_model(model)
    return len(encoding.encode(text))

# Check before sending
if count_tokens(prompt) > 4000:
    # Truncate or split prompt
    prompt = truncate_prompt(prompt, max_tokens=4000)
```

**Estimate costs:**
```python
def estimate_cost(prompt: str, model: str = "gpt-4") -> float:
    input_tokens = count_tokens(prompt)
    
    # Pricing per 1K tokens (example)
    prices = {
        "gpt-4": {"input": 0.03, "output": 0.06},
        "gpt-3.5-turbo": {"input": 0.0015, "output": 0.002}
    }
    
    input_cost = (input_tokens / 1000) * prices[model]["input"]
    # Estimate output (e.g., 30% of input)
    output_cost = (input_tokens * 0.3 / 1000) * prices[model]["output"]
    
    return input_cost + output_cost
```

### Error Handling

```python
from opencontext.llm.llm_client import LLMError, RateLimitError

try:
    response = client.complete(prompt)
except RateLimitError:
    # Handle rate limiting
    logger.warning("Rate limit hit, waiting...")
    time.sleep(60)
    response = client.complete(prompt)
except LLMError as e:
    # Handle other LLM errors
    logger.error(f"LLM error: {e}")
    # Fallback behavior
    response = fallback_response()
```

### Caching

**Cache frequent queries:**
```python
from functools import lru_cache
import hashlib

@lru_cache(maxsize=1000)
def cached_complete(prompt_hash: str, prompt: str) -> str:
    client = LLMClient.get_instance()
    return client.complete(prompt)

def complete_with_cache(prompt: str) -> str:
    # Hash prompt for caching
    prompt_hash = hashlib.md5(prompt.encode()).hexdigest()
    return cached_complete(prompt_hash, prompt)
```

## 📈 Performance Optimization

### 1. Batch Processing

```python
# Instead of individual calls
for text in texts:
    embedding = client.embed(text)  # Slow

# Use batch
embeddings = client.batch_embed(texts)  # Fast
```

### 2. Async Operations

```python
import asyncio

async def async_embed(text: str) -> List[float]:
    client = GlobalEmbeddingClient.get_instance()
    return await client.async_embed(text)

# Process multiple concurrently
tasks = [async_embed(text) for text in texts]
embeddings = await asyncio.gather(*tasks)
```

### 3. Connection Pooling

```python
# Configure in client
client = LLMClient(
    api_key="key",
    model="gpt-4",
    connection_pool_size=10  # Reuse connections
)
```

## 🔒 Security Best Practices

1. **API Key Management**
   ```python
   # Use environment variables
   import os
   api_key = os.getenv("OPENAI_API_KEY")
   
   # Never hardcode keys
   # api_key = "sk-..."  # DON'T DO THIS
   ```

2. **Input Validation**
   ```python
   def validate_prompt(prompt: str) -> bool:
       # Check length
       if len(prompt) > 10000:
           return False
       # Filter sensitive patterns
       if contains_sensitive_data(prompt):
           return False
       return True
   ```

3. **Rate Limiting**
   ```python
   from ratelimit import limits, sleep_and_retry
   
   @sleep_and_retry
   @limits(calls=50, period=60)  # 50 calls per minute
   def call_llm(prompt: str) -> str:
       return client.complete(prompt)
   ```

## 📚 Prompt Engineering

### Tips for Better Prompts

1. **Be Specific**
   ```python
   # Bad
   prompt = "Summarize this"
   
   # Good
   prompt = """Summarize this document in 3-5 sentences, 
   focusing on key findings and actionable items."""
   ```

2. **Provide Context**
   ```python
   prompt = f"""You are analyzing a software developer's activity.
   
   Context: {relevant_context}
   
   Task: Extract coding tasks and bugs mentioned.
   """
   ```

3. **Use Examples**
   ```python
   prompt = """Extract keywords from text.
   
   Example:
   Input: "Machine learning models for NLP"
   Output: ["machine learning", "models", "NLP"]
   
   Input: {text}
   Output:"""
   ```

4. **Structure Output**
   ```python
   prompt = """Analyze this text and return JSON:
   {
     "summary": "brief summary",
     "keywords": ["key1", "key2"],
     "sentiment": "positive|negative|neutral"
   }
   
   Text: {text}
   """
   ```

## 🔗 Related Documentation

- [Architecture Overview](./03-architecture-overview.md)
- [Configuration Guide](./05-configuration-guide.md)
- [Context Processing](./10-context-processing.md)
- [Development Guide](./12-development-guide.md)
