# Web Interface Documentation

This document covers MineContext's web interface architecture, components, and development.

## 🌐 Web Architecture

```
┌─────────────────────────────────────────────────┐
│              FastAPI Backend                     │
│  - Serves HTML templates                        │
│  - REST API endpoints                           │
│  - WebSocket connections                        │
│  - Static file serving                          │
└──────────────────┬──────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────┐
│         Web Interface (opencontext/web/)        │
├─────────────────────────────────────────────────┤
│  templates/          │  static/                 │
│  - agent_chat.html   │  - css/                  │
│  - note_editor.html  │    - agent_chat.css      │
│  - index.html        │    - note_editor.css     │
│                      │  - js/                   │
│                      │    - agent_chat.js       │
│                      │    - note_editor.js      │
│                      │  - images/               │
└──────────────────────┴──────────────────────────┘
```

## 📁 Directory Structure

```
opencontext/web/
├── templates/          # Jinja2 HTML templates
│   ├── agent_chat.html      # AI chat interface
│   ├── note_editor.html     # Document editor
│   ├── base.html            # Base template
│   └── index.html           # Landing page
│
└── static/            # Static assets
    ├── css/
    │   ├── agent_chat.css   # Chat interface styles
    │   ├── note_editor.css  # Editor styles
    │   ├── common.css       # Shared styles
    │   └── themes/          # Theme files
    │
    ├── js/
    │   ├── agent_chat.js    # Chat functionality
    │   ├── note_editor.js   # Editor functionality
    │   ├── common.js        # Shared utilities
    │   └── lib/             # Third-party libraries
    │       ├── codemirror/  # Code editor
    │       ├── marked.js    # Markdown parser
    │       └── highlight.js # Syntax highlighting
    │
    └── images/          # Images and icons
        ├── logo.svg
        └── icons/
```

## 🎨 Main Pages

### 1. Agent Chat Interface (`agent_chat.html`)

The primary interface for AI interaction and document management.

**Layout:**

```
┌──────────────────────────────────────────────────────┐
│                    Top Bar                            │
│  [Logo] MineContext    Theme Toggle  Settings        │
├─────────────┬────────────────────────┬───────────────┤
│  Documents  │  Editor / Preview      │  Chat Panel   │
│   Panel     │                        │               │
│             │  ┌──────────────────┐  │  [Messages]   │
│  [📄 Doc 1] │  │                  │  │               │
│  [📄 Doc 2] │  │  Document        │  │  ┌─────────┐ │
│  [📄 Doc 3] │  │  Content         │  │  │ Input   │ │
│             │  │                  │  │  └─────────┘ │
│  [+ New]    │  │                  │  │  [Send]      │
│  [🗑 Delete]│  └──────────────────┘  │               │
│             │  [Save] [Preview]      │               │
└─────────────┴────────────────────────┴───────────────┘
```

**Key Features:**

1. **Document List Panel**
   - Browse documents
   - Create new documents
   - Delete documents
   - Filter and search

2. **Editor Panel**
   - CodeMirror-based Markdown editor
   - Live preview toggle
   - Auto-save functionality
   - Smart completion

3. **Chat Panel**
   - AI conversation interface
   - Context-aware responses
   - Action confirmation
   - Message history

**JavaScript API:**

```javascript
// Main class
class AgentChatManager {
    constructor() {
        this.documents = [];
        this.currentDocument = null;
        this.editor = null;
        this.ws = null;  // WebSocket connection
    }
    
    // Document management
    async loadDocuments() { }
    async loadDocument(docId) { }
    async createNewDocument() { }
    async saveDocument() { }
    async deleteCurrentDocument() { }
    
    // Editor functionality
    initEditor() { }
    handleEditorChange(cm, change) { }
    
    // Chat functionality
    async sendMessage() { }
    async handleAIResponse(response) { }
    approveConfirmation() { }
    rejectConfirmation() { }
    
    // Completion
    async getCompletion(text, position) { }
    showCompletionSuggestions(suggestions) { }
}
```

**Usage Example:**

```javascript
// Initialize
const agentChat = new AgentChatManager();

// Send message
async function sendMessage() {
    const input = document.getElementById('chatInput');
    const message = input.value.trim();
    
    if (!message) return;
    
    // Add user message to UI
    agentChat.addMessage('user', message);
    
    // Send to backend
    const response = await fetch('/api/agent/chat', {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify({
            message: message,
            context: {
                selected_documents: [agentChat.currentDocument?.id],
                selected_text: agentChat.getSelectedText()
            }
        })
    });
    
    const data = await response.json();
    
    // Add AI response
    agentChat.addMessage('assistant', data.response);
    
    // Handle actions
    if (data.actions) {
        agentChat.handleActions(data.actions);
    }
}
```

### 2. Note Editor (`note_editor.html`)

Dedicated document editing interface.

**Layout:**

```
┌──────────────────────────────────────────────────────┐
│                Document Sidebar                       │
├─────────────┬────────────────────────────────────────┤
│  My Notes   │         Editor                         │
│             │  ┌──────────────────────────────────┐  │
│  [📝 Note1] │  │ Title: [Document Title]          │  │
│  [📝 Note2] │  ├──────────────────────────────────┤  │
│  [📝 Note3] │  │                                  │  │
│             │  │  # Heading                       │  │
│  [+ New]    │  │                                  │  │
│  [💾 Save]  │  │  Content here...                 │  │
│  [🗑Delete] │  │                                  │  │
│             │  │                                  │  │
│             │  │                                  │  │
│             │  └──────────────────────────────────┘  │
│             │  [Preview] [Settings]                  │
└─────────────┴────────────────────────────────────────┘
```

**JavaScript API:**

```javascript
class NoteEditor {
    constructor() {
        this.documents = [];
        this.currentDocument = null;
        this.editor = null;
        this.autoSaveTimer = null;
    }
    
    // Document operations
    async loadDocuments() { }
    async loadDocument(docId) { }
    async createNewDocument() { }
    async saveDocument() { }
    async deleteCurrentDocument() { }
    
    // Editor
    initEditor() { }
    setupAutoSave() { }
    togglePreview() { }
    
    // Completion
    setupCompletionHandler() { }
    handleTabKey(cm) { }
}
```

### 3. Landing Page (`index.html`)

Home dashboard showing summaries, todos, and tips.

**Layout:**

```
┌──────────────────────────────────────────────────────┐
│                  Welcome Banner                       │
│           MineContext - Your AI Partner              │
├──────────────────────────────────────────────────────┤
│  ┌────────────────┐  ┌────────────────┐             │
│  │ Daily Summary  │  │   Todo List    │             │
│  │                │  │  □ Task 1      │             │
│  │ Today you...   │  │  ☑ Task 2      │             │
│  │                │  │  □ Task 3      │             │
│  └────────────────┘  └────────────────┘             │
│                                                       │
│  ┌────────────────┐  ┌────────────────┐             │
│  │    Tips        │  │   Activity     │             │
│  │                │  │   Timeline     │             │
│  │ 💡 Tip 1       │  │                │             │
│  │ 💡 Tip 2       │  │  [Timeline]    │             │
│  └────────────────┘  └────────────────┘             │
└──────────────────────────────────────────────────────┘
```

## 🎨 Styling

### CSS Architecture

**Base Styles (`common.css`):**

```css
:root {
    /* Color palette */
    --primary-color: #4a90e2;
    --secondary-color: #7b68ee;
    --background: #ffffff;
    --text-primary: #333333;
    --text-secondary: #666666;
    --border-color: #e0e0e0;
    
    /* Spacing */
    --spacing-xs: 4px;
    --spacing-sm: 8px;
    --spacing-md: 16px;
    --spacing-lg: 24px;
    --spacing-xl: 32px;
    
    /* Typography */
    --font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto;
    --font-size-base: 14px;
    --font-size-lg: 16px;
    --font-size-sm: 12px;
}

/* Dark theme */
[data-theme="dark"] {
    --background: #1e1e1e;
    --text-primary: #e0e0e0;
    --text-secondary: #a0a0a0;
    --border-color: #333333;
}

/* Base layout */
body {
    font-family: var(--font-family);
    font-size: var(--font-size-base);
    color: var(--text-primary);
    background: var(--background);
    margin: 0;
    padding: 0;
}

/* Components */
.button {
    padding: var(--spacing-sm) var(--spacing-md);
    border: 1px solid var(--border-color);
    border-radius: 4px;
    cursor: pointer;
    transition: all 0.2s;
}

.button:hover {
    background: var(--primary-color);
    color: white;
}
```

**Component Styles:**

```css
/* Document list */
.documents-panel {
    width: 250px;
    border-right: 1px solid var(--border-color);
    overflow-y: auto;
}

.document-item {
    padding: var(--spacing-md);
    cursor: pointer;
    transition: background 0.2s;
}

.document-item:hover {
    background: rgba(0, 0, 0, 0.05);
}

.document-item.active {
    background: var(--primary-color);
    color: white;
}

/* Editor */
.document-editor {
    flex: 1;
    display: flex;
    flex-direction: column;
}

.CodeMirror {
    height: 100%;
    font-family: 'Monaco', 'Menlo', monospace;
    font-size: 14px;
}

/* Chat panel */
.chat-panel {
    width: 400px;
    border-left: 1px solid var(--border-color);
    display: flex;
    flex-direction: column;
}

.chat-messages {
    flex: 1;
    overflow-y: auto;
    padding: var(--spacing-md);
}

.message {
    margin-bottom: var(--spacing-md);
    padding: var(--spacing-sm);
    border-radius: 8px;
}

.message.user {
    background: var(--primary-color);
    color: white;
    margin-left: auto;
    max-width: 80%;
}

.message.assistant {
    background: var(--border-color);
    max-width: 80%;
}
```

### Responsive Design

```css
/* Mobile */
@media (max-width: 768px) {
    .documents-panel {
        width: 100%;
        height: 200px;
        border-right: none;
        border-bottom: 1px solid var(--border-color);
    }
    
    .chat-panel {
        width: 100%;
        border-left: none;
        border-top: 1px solid var(--border-color);
    }
    
    .main-container {
        flex-direction: column;
    }
}

/* Tablet */
@media (max-width: 1024px) {
    .documents-panel {
        width: 200px;
    }
    
    .chat-panel {
        width: 300px;
    }
}
```

## 🔌 WebSocket Integration

### Connection Setup

```javascript
class WebSocketManager {
    constructor() {
        this.ws = null;
        this.reconnectAttempts = 0;
        this.maxReconnectAttempts = 5;
    }
    
    connect() {
        const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
        const wsUrl = `${protocol}//${window.location.host}/ws/events`;
        
        this.ws = new WebSocket(wsUrl);
        
        this.ws.onopen = () => {
            console.log('WebSocket connected');
            this.reconnectAttempts = 0;
        };
        
        this.ws.onmessage = (event) => {
            const data = JSON.parse(event.data);
            this.handleMessage(data);
        };
        
        this.ws.onerror = (error) => {
            console.error('WebSocket error:', error);
        };
        
        this.ws.onclose = () => {
            console.log('WebSocket closed');
            this.reconnect();
        };
    }
    
    reconnect() {
        if (this.reconnectAttempts >= this.maxReconnectAttempts) {
            console.error('Max reconnect attempts reached');
            return;
        }
        
        this.reconnectAttempts++;
        const delay = Math.min(1000 * Math.pow(2, this.reconnectAttempts), 30000);
        
        setTimeout(() => {
            console.log('Reconnecting...');
            this.connect();
        }, delay);
    }
    
    handleMessage(data) {
        switch (data.type) {
            case 'context_added':
                this.onContextAdded(data);
                break;
            case 'context_updated':
                this.onContextUpdated(data);
                break;
            case 'generation_complete':
                this.onGenerationComplete(data);
                break;
        }
    }
    
    send(data) {
        if (this.ws && this.ws.readyState === WebSocket.OPEN) {
            this.ws.send(JSON.stringify(data));
        }
    }
}

// Initialize
const wsManager = new WebSocketManager();
wsManager.connect();
```

### Real-time Updates

```javascript
// Update UI when context is added
wsManager.onContextAdded = (data) => {
    // Refresh document list
    agentChat.loadDocuments();
    
    // Show notification
    showNotification('New context captured');
};

// Update when generation completes
wsManager.onGenerationComplete = (data) => {
    if (data.generation_type === 'daily_summary') {
        // Refresh home dashboard
        refreshDashboard();
    }
};
```

## 🔧 Editor Integration

### CodeMirror Setup

```javascript
function initEditor() {
    this.editor = CodeMirror.fromTextArea(
        document.getElementById('editor'),
        {
            mode: 'markdown',
            theme: 'monokai',
            lineNumbers: true,
            lineWrapping: true,
            autofocus: true,
            extraKeys: {
                'Tab': (cm) => this.handleTabKey(cm),
                'Esc': (cm) => this.handleEscapeKey(cm),
                'Ctrl-S': () => this.saveDocument(),
                'Cmd-S': () => this.saveDocument()
            }
        }
    );
    
    // Handle changes
    this.editor.on('change', (cm, change) => {
        this.handleEditorChange(cm, change);
    });
    
    // Handle cursor activity
    this.editor.on('cursorActivity', (cm) => {
        this.handleCursorActivity(cm);
    });
}
```

### Auto-completion

```javascript
async function getCompletion() {
    const cursor = this.editor.getCursor();
    const line = cursor.line;
    const ch = cursor.ch;
    
    // Get text before cursor
    const textBefore = this.editor.getRange(
        {line: Math.max(0, line - 5), ch: 0},
        {line, ch}
    );
    
    // Request completion
    const response = await fetch('/api/completions/suggest', {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify({
            text: textBefore,
            cursor_position: textBefore.length,
            document_id: this.currentDocument?.id
        })
    });
    
    const data = await response.json();
    
    // Show suggestions
    if (data.suggestions && data.suggestions.length > 0) {
        this.showCompletionWidget(data.suggestions, cursor);
    }
}

function showCompletionWidget(suggestions, cursor) {
    // Create widget
    const widget = document.createElement('div');
    widget.className = 'completion-widget';
    
    suggestions.forEach((suggestion, index) => {
        const item = document.createElement('div');
        item.className = 'completion-item';
        item.textContent = suggestion.text;
        item.onclick = () => {
            this.acceptCompletion(suggestion.text);
            widget.remove();
        };
        
        if (index === 0) {
            item.classList.add('selected');
        }
        
        widget.appendChild(item);
    });
    
    // Position widget
    const coords = this.editor.cursorCoords(cursor);
    widget.style.top = `${coords.bottom}px`;
    widget.style.left = `${coords.left}px`;
    
    document.body.appendChild(widget);
}
```

## 📊 State Management

```javascript
class StateManager {
    constructor() {
        this.state = {
            documents: [],
            currentDocument: null,
            theme: 'light',
            settings: {}
        };
        
        this.listeners = [];
    }
    
    setState(newState) {
        this.state = {...this.state, ...newState};
        this.notifyListeners();
    }
    
    getState() {
        return this.state;
    }
    
    subscribe(listener) {
        this.listeners.push(listener);
        return () => {
            this.listeners = this.listeners.filter(l => l !== listener);
        };
    }
    
    notifyListeners() {
        this.listeners.forEach(listener => listener(this.state));
    }
}

// Usage
const state = new StateManager();

state.subscribe((newState) => {
    console.log('State updated:', newState);
    updateUI(newState);
});

state.setState({
    currentDocument: { id: 1, title: 'New Doc' }
});
```

## 🔒 Security

### CSRF Protection

```javascript
// Get CSRF token
const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content;

// Include in requests
fetch('/api/endpoint', {
    method: 'POST',
    headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': csrfToken
    },
    body: JSON.stringify(data)
});
```

### Input Sanitization

```javascript
function sanitizeInput(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

// Use when displaying user input
element.innerHTML = sanitizeInput(userInput);
```

## 📚 Related Documentation

- [Architecture Overview](./03-architecture-overview.md)
- [API Reference](./06-api-reference.md)
- [Development Guide](./12-development-guide.md)
- [User Guide](./02-user-guide.md)
