# API Reference

This document provides a complete reference for MineContext's REST API endpoints.

## 🌐 Base URL

Default: `http://localhost:8765`

Configured via `config/config.yaml`:
```yaml
server:
  host: 127.0.0.1
  port: 8765
```

## 🔐 Authentication

Currently, MineContext uses a simple token-based authentication for API endpoints.

**Header:**
```
Authorization: Bearer your-token-here
```

**Note:** Authentication can be configured in `config/config.yaml`.

## 📋 API Endpoints

### Health & Status

#### GET /health

Check system health status.

**Response:**
```json
{
  "status": "healthy",
  "components": {
    "config": true,
    "storage": true,
    "llm": true,
    "capture": true,
    "consumption": true
  }
}
```

**Status Codes:**
- `200 OK` - System is healthy
- `503 Service Unavailable` - One or more components are unhealthy

---

### Context Management

#### GET /api/contexts

Get all processed contexts with pagination and filtering.

**Query Parameters:**
- `limit` (int, default: 10) - Number of results to return
- `offset` (int, default: 0) - Number of results to skip
- `context_type` (string, optional) - Filter by context type
- `start_date` (string, optional) - Filter by start date (ISO 8601)
- `end_date` (string, optional) - Filter by end date (ISO 8601)

**Example:**
```http
GET /api/contexts?limit=20&offset=0&context_type=ACTIVITY
```

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "doc_id": "abc123",
      "title": "Activity at 14:30",
      "summary": "Working on documentation",
      "context_type": "ACTIVITY",
      "create_time": "2025-01-01T14:30:00",
      "update_time": "2025-01-01T14:30:00",
      "tags": ["work", "documentation"],
      "importance": 5
    }
  ],
  "total": 100,
  "limit": 20,
  "offset": 0
}
```

#### GET /api/contexts/{doc_id}

Get a specific context by ID.

**Path Parameters:**
- `doc_id` (string) - Document ID

**Example:**
```http
GET /api/contexts/abc123
```

**Response:**
```json
{
  "success": true,
  "data": {
    "doc_id": "abc123",
    "title": "Activity at 14:30",
    "summary": "Working on documentation",
    "content": "Full content here...",
    "chunks": [
      {
        "text": "Chunk content...",
        "chunk_index": 0
      }
    ],
    "extracted_data": {
      "keywords": ["work", "docs"],
      "entities": ["MineContext"],
      "tags": ["work"]
    },
    "context_type": "ACTIVITY",
    "create_time": "2025-01-01T14:30:00"
  }
}
```

#### POST /api/contexts/search

Search contexts using vector similarity.

**Request Body:**
```json
{
  "query": "AI projects",
  "top_k": 10,
  "context_types": ["DOCUMENT", "ACTIVITY"],
  "filters": {
    "start_date": "2025-01-01T00:00:00",
    "tags": ["AI"]
  }
}
```

**Response:**
```json
{
  "success": true,
  "results": [
    {
      "doc_id": "xyz789",
      "title": "AI Project Notes",
      "summary": "Notes about AI project...",
      "score": 0.95,
      "context_type": "DOCUMENT"
    }
  ]
}
```

#### DELETE /api/contexts/{doc_id}

Delete a context.

**Path Parameters:**
- `doc_id` (string) - Document ID

**Response:**
```json
{
  "success": true,
  "message": "Context deleted successfully"
}
```

---

### Vaults (Document Management)

#### GET /api/vaults/list

List all vault documents.

**Query Parameters:**
- `limit` (int, default: 50) - Number of results
- `offset` (int, default: 0) - Offset for pagination

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "title": "My Notes",
      "summary": "Important notes",
      "document_type": "note",
      "create_time": "2025-01-01T12:00:00",
      "update_time": "2025-01-01T12:00:00"
    }
  ],
  "total": 10
}
```

#### POST /api/vaults/create

Create a new document.

**Request Body:**
```json
{
  "title": "New Document",
  "content": "Document content here...",
  "summary": "Brief summary",
  "tags": "tag1,tag2",
  "document_type": "note"
}
```

**Response:**
```json
{
  "success": true,
  "doc_id": 123,
  "message": "Document created successfully"
}
```

#### PUT /api/vaults/update/{doc_id}

Update an existing document.

**Path Parameters:**
- `doc_id` (int) - Document ID

**Request Body:**
```json
{
  "title": "Updated Title",
  "content": "Updated content...",
  "summary": "Updated summary",
  "tags": "new,tags"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Document updated successfully"
}
```

#### DELETE /api/vaults/delete/{doc_id}

Delete a document.

**Path Parameters:**
- `doc_id` (int) - Document ID

**Response:**
```json
{
  "success": true,
  "message": "Document deleted successfully"
}
```

---

### Agent Chat

#### POST /api/agent/chat

Send a message to the AI agent.

**Request Body:**
```json
{
  "message": "Help me create a todo list",
  "context": {
    "selected_documents": [1, 2, 3],
    "conversation_history": []
  },
  "stream": false
}
```

**Response (Non-streaming):**
```json
{
  "success": true,
  "response": "I'll help you create a todo list...",
  "actions": [
    {
      "type": "create_todo",
      "data": {
        "title": "Complete project",
        "description": "Finish the documentation"
      }
    }
  ]
}
```

**Response (Streaming):**
When `stream: true`, returns Server-Sent Events (SSE):
```
data: {"type": "token", "content": "I'll"}
data: {"type": "token", "content": " help"}
data: {"type": "action", "action": {...}}
data: {"type": "done"}
```

#### POST /api/agent/confirmation

Approve or reject an agent action.

**Request Body:**
```json
{
  "action_id": "action_123",
  "approved": true,
  "feedback": "Looks good"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Action executed successfully"
}
```

---

### Smart Completion

#### POST /api/completions/suggest

Get smart completion suggestions.

**Request Body:**
```json
{
  "text": "I need to finish the",
  "cursor_position": 20,
  "document_id": 123,
  "max_suggestions": 3
}
```

**Response:**
```json
{
  "success": true,
  "suggestions": [
    {
      "text": " project by Friday",
      "score": 0.9
    },
    {
      "text": " report by end of week",
      "score": 0.8
    }
  ]
}
```

#### POST /api/completions/accept

Record that a completion was accepted (for learning).

**Request Body:**
```json
{
  "text": "original text",
  "completion": "accepted completion",
  "document_id": 123
}
```

**Response:**
```json
{
  "success": true,
  "message": "Feedback recorded"
}
```

---

### Screenshots

#### GET /api/screenshots

List captured screenshots.

**Query Parameters:**
- `limit` (int, default: 50)
- `offset` (int, default: 0)
- `start_date` (string, optional)
- `end_date` (string, optional)

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "path": "/screenshots/2025-01-01_12-00-00.png",
      "window": "Browser",
      "app": "Chrome",
      "create_time": "2025-01-01T12:00:00"
    }
  ]
}
```

#### POST /api/screenshots/trigger

Manually trigger a screenshot capture.

**Response:**
```json
{
  "success": true,
  "message": "Screenshot captured successfully",
  "path": "/screenshots/2025-01-01_12-00-00.png"
}
```

---

### Content Generation

#### POST /api/generation/summary

Generate a summary for a time period.

**Request Body:**
```json
{
  "start_date": "2025-01-01T00:00:00",
  "end_date": "2025-01-01T23:59:59",
  "summary_type": "daily"
}
```

**Response:**
```json
{
  "success": true,
  "summary": {
    "title": "Daily Summary - 2025-01-01",
    "content": "Today you worked on...",
    "highlights": ["Completed documentation", "Met with team"]
  }
}
```

#### POST /api/generation/todos

Extract todos from recent contexts.

**Request Body:**
```json
{
  "context_ids": ["doc1", "doc2"],
  "auto_create": false
}
```

**Response:**
```json
{
  "success": true,
  "todos": [
    {
      "title": "Complete project",
      "description": "Finish by Friday",
      "priority": "high",
      "source_context": "doc1"
    }
  ]
}
```

#### POST /api/generation/tips

Generate tips and insights.

**Request Body:**
```json
{
  "context_count": 50,
  "time_range": "week"
}
```

**Response:**
```json
{
  "success": true,
  "tips": [
    {
      "title": "Productivity Pattern",
      "content": "You're most productive in the morning",
      "type": "insight"
    }
  ]
}
```

---

### Monitoring

#### GET /api/monitoring/stats

Get system statistics.

**Response:**
```json
{
  "success": true,
  "stats": {
    "captures": {
      "total": 1000,
      "by_source": {
        "SCREENSHOT": 800,
        "VAULT": 200
      }
    },
    "storage": {
      "total_contexts": 950,
      "total_size_mb": 1024
    },
    "processing": {
      "avg_time_ms": 250,
      "success_rate": 0.98
    }
  }
}
```

#### GET /api/monitoring/metrics

Get detailed metrics.

**Query Parameters:**
- `start_date` (string, optional)
- `end_date` (string, optional)
- `metric_type` (string, optional) - Filter by metric type

**Response:**
```json
{
  "success": true,
  "metrics": [
    {
      "timestamp": "2025-01-01T12:00:00",
      "metric_type": "capture_rate",
      "value": 12.5
    }
  ]
}
```

---

### Settings

#### GET /api/settings

Get current configuration.

**Response:**
```json
{
  "success": true,
  "settings": {
    "capture": {
      "enabled": true,
      "screenshot": {
        "enabled": true,
        "interval": 5
      }
    },
    "llm": {
      "provider": "doubao",
      "model": "doubao-embedding-large-text-240915"
    }
  }
}
```

#### PUT /api/settings

Update configuration.

**Request Body:**
```json
{
  "capture": {
    "screenshot": {
      "interval": 10
    }
  }
}
```

**Response:**
```json
{
  "success": true,
  "message": "Settings updated successfully"
}
```

---

### Events (WebSocket)

#### WS /ws/events

WebSocket endpoint for real-time events.

**Connection:**
```javascript
const ws = new WebSocket('ws://localhost:8765/ws/events');

ws.onopen = () => {
  console.log('Connected');
};

ws.onmessage = (event) => {
  const data = JSON.parse(event.data);
  // Handle event
};
```

**Event Types:**

1. **context_added**
```json
{
  "type": "context_added",
  "data": {
    "doc_id": "abc123",
    "context_type": "ACTIVITY"
  }
}
```

2. **context_updated**
```json
{
  "type": "context_updated",
  "data": {
    "doc_id": "abc123"
  }
}
```

3. **capture_event**
```json
{
  "type": "capture_event",
  "data": {
    "source": "SCREENSHOT",
    "count": 1
  }
}
```

4. **generation_complete**
```json
{
  "type": "generation_complete",
  "data": {
    "generation_type": "daily_summary",
    "doc_id": "summary_123"
  }
}
```

---

## 📊 Response Format

All API responses follow a consistent format:

**Success Response:**
```json
{
  "success": true,
  "data": { ... },
  "message": "Optional success message"
}
```

**Error Response:**
```json
{
  "success": false,
  "error": "Error message",
  "details": "Optional detailed error information"
}
```

## 🚦 HTTP Status Codes

- `200 OK` - Request successful
- `201 Created` - Resource created
- `400 Bad Request` - Invalid request parameters
- `401 Unauthorized` - Authentication required
- `403 Forbidden` - Permission denied
- `404 Not Found` - Resource not found
- `500 Internal Server Error` - Server error
- `503 Service Unavailable` - Service temporarily unavailable

## 🔄 Rate Limiting

Currently, no rate limiting is enforced. Consider implementing rate limiting for production deployments.

## 📝 Examples

### Python Example

```python
import requests

BASE_URL = "http://localhost:8765"

# Search contexts
response = requests.post(
    f"{BASE_URL}/api/contexts/search",
    json={
        "query": "AI projects",
        "top_k": 5
    }
)

results = response.json()
print(results)
```

### JavaScript Example

```javascript
const BASE_URL = 'http://localhost:8765';

// Create document
async function createDocument() {
  const response = await fetch(`${BASE_URL}/api/vaults/create`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      title: 'My Document',
      content: 'Document content...'
    })
  });
  
  const result = await response.json();
  return result;
}
```

### cURL Example

```bash
# Get health status
curl http://localhost:8765/health

# Search contexts
curl -X POST http://localhost:8765/api/contexts/search \
  -H "Content-Type: application/json" \
  -d '{"query": "AI projects", "top_k": 5}'

# Create document
curl -X POST http://localhost:8765/api/vaults/create \
  -H "Content-Type: application/json" \
  -d '{
    "title": "New Document",
    "content": "Content here..."
  }'
```

## 🔗 Related Documentation

- [Architecture Overview](./03-architecture-overview.md)
- [Data Flow & Workflow](./04-data-flow-workflow.md)
- [Configuration Guide](./05-configuration-guide.md)
- [Development Guide](./12-development-guide.md)
