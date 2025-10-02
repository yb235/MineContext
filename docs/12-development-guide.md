# Development Guide

This guide is for developers who want to contribute to MineContext or extend its functionality.

## 🚀 Getting Started

### Development Environment Setup

1. **Clone the Repository**
   ```bash
   git clone https://github.com/volcengine/MineContext.git
   cd MineContext
   ```

2. **Create Virtual Environment**
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

3. **Install Dependencies**
   ```bash
   pip install -r requirements.txt
   ```

4. **Install Development Dependencies**
   ```bash
   pip install pytest pytest-cov black flake8 mypy
   ```

5. **Set Up Pre-commit Hooks (Optional)**
   ```bash
   pip install pre-commit
   pre-commit install
   ```

### Project Structure

```
MineContext/
├── opencontext/              # Main package
│   ├── __init__.py
│   ├── cli.py               # Command-line interface
│   ├── config/              # Configuration management
│   ├── context_capture/     # Capture components
│   ├── context_processing/  # Processing pipeline
│   ├── context_consumption/ # Generation & consumption
│   ├── llm/                 # LLM integration
│   ├── managers/            # Component managers
│   ├── models/              # Data models
│   ├── monitoring/          # System monitoring
│   ├── server/              # API server
│   ├── storage/             # Storage backends
│   ├── tools/               # Agent tools
│   ├── utils/               # Utilities
│   └── web/                 # Web interface
│       ├── static/          # CSS, JS, images
│       └── templates/       # HTML templates
├── config/                  # Configuration files
├── docs/                    # Documentation
├── tests/                   # Test suite
├── requirements.txt         # Dependencies
└── README.md               # Main readme

```

## 🛠️ Development Workflow

### 1. Create a Feature Branch

```bash
git checkout -b feature/your-feature-name
```

### 2. Make Changes

Follow the coding standards (see below).

### 3. Run Tests

```bash
# Run all tests
pytest

# Run with coverage
pytest --cov=opencontext tests/

# Run specific test file
pytest tests/test_capture.py
```

### 4. Format Code

```bash
# Format with black
black opencontext/

# Check with flake8
flake8 opencontext/

# Type checking
mypy opencontext/
```

### 5. Commit Changes

```bash
git add .
git commit -m "Add feature: description"
```

**Commit Message Format:**
```
<type>: <subject>

<body>

<footer>
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes
- `refactor`: Code refactoring
- `test`: Test changes
- `chore`: Build/config changes

### 6. Push and Create PR

```bash
git push origin feature/your-feature-name
```

Then create a Pull Request on GitHub.

## 📝 Coding Standards

### Python Style Guide

Follow [PEP 8](https://pep8.org/) with these specific guidelines:

**Formatting:**
- Use 4 spaces for indentation
- Max line length: 100 characters
- Use double quotes for strings
- Add docstrings to all public functions/classes

**Naming Conventions:**
```python
# Classes: PascalCase
class ContextProcessor:
    pass

# Functions/Methods: snake_case
def process_context(context):
    pass

# Constants: UPPER_SNAKE_CASE
MAX_RETRIES = 3

# Private: prefix with underscore
def _internal_function():
    pass
```

**Docstrings:**
```python
def process_context(context: RawContextProperties) -> ProcessedContext:
    """
    Process raw context into structured format.
    
    Args:
        context: Raw context properties to process
        
    Returns:
        Processed context with extracted data
        
    Raises:
        ValueError: If context format is invalid
    """
    pass
```

### JavaScript Style Guide

**Formatting:**
- Use 2 spaces for indentation
- Use semicolons
- Use single quotes for strings
- Use const/let, not var

**Example:**
```javascript
class AgentChatManager {
  constructor() {
    this.messages = [];
  }
  
  async sendMessage(text) {
    const response = await fetch('/api/agent/chat', {
      method: 'POST',
      body: JSON.stringify({ message: text })
    });
    return response.json();
  }
}
```

## 🧪 Testing

### Writing Tests

**Test Structure:**
```python
# tests/test_capture.py
import pytest
from opencontext.context_capture.screenshot import ScreenshotCapture

class TestScreenshotCapture:
    @pytest.fixture
    def capture(self):
        return ScreenshotCapture()
    
    def test_initialize(self, capture):
        """Test capture initialization."""
        config = {"enabled": True, "interval": 5}
        assert capture.initialize(config)
    
    def test_capture_screenshot(self, capture):
        """Test screenshot capture."""
        contexts = capture.capture()
        assert len(contexts) > 0
        assert contexts[0].source == ContextSource.SCREENSHOT
```

**Test Categories:**

1. **Unit Tests** - Test individual functions/methods
   ```python
   def test_chunk_text():
       chunker = FixedChunker(chunk_size=100)
       chunks = chunker.chunk("text here...")
       assert len(chunks) > 0
   ```

2. **Integration Tests** - Test component interactions
   ```python
   def test_capture_to_storage():
       capture = ScreenshotCapture()
       storage = UnifiedStorage()
       contexts = capture.capture()
       assert storage.insert_processed_context(contexts[0])
   ```

3. **End-to-End Tests** - Test complete workflows
   ```python
   def test_complete_workflow():
       app = OpenContext()
       app.initialize()
       # Test complete capture -> process -> store flow
   ```

### Running Tests

```bash
# All tests
pytest

# Specific test file
pytest tests/test_capture.py

# Specific test
pytest tests/test_capture.py::TestScreenshotCapture::test_initialize

# With coverage
pytest --cov=opencontext --cov-report=html

# Fast (skip slow tests)
pytest -m "not slow"
```

### Test Fixtures

```python
# tests/conftest.py
import pytest
from opencontext.storage import UnifiedStorage

@pytest.fixture
def storage():
    """Provide test storage instance."""
    storage = UnifiedStorage()
    storage.initialize()
    yield storage
    storage.clear()  # Cleanup

@pytest.fixture
def sample_context():
    """Provide sample context for testing."""
    return RawContextProperties(
        source=ContextSource.SCREENSHOT,
        content_format=ContentFormat.IMAGE,
        content_path="/test/image.png"
    )
```

## 🔌 Extending MineContext

### Adding a New Capture Source

1. **Create Capture Component**

```python
# opencontext/context_capture/custom_capture.py
from opencontext.interfaces import ICaptureComponent
from opencontext.models import RawContextProperties, ContextSource

class CustomCapture(ICaptureComponent):
    def __init__(self):
        self._callback = None
        self._running = False
    
    def initialize(self, config: Dict) -> bool:
        """Initialize the capture component."""
        # Setup configuration
        return True
    
    def start(self) -> bool:
        """Start capturing."""
        self._running = True
        # Start capture thread/timer
        return True
    
    def stop(self, graceful: bool = True) -> bool:
        """Stop capturing."""
        self._running = False
        return True
    
    def capture(self) -> List[RawContextProperties]:
        """Perform single capture."""
        # Implement capture logic
        context = RawContextProperties(
            source=ContextSource.CUSTOM,
            content_format=ContentFormat.TEXT,
            content_text="captured data"
        )
        return [context]
    
    def set_callback(self, callback: Callable) -> None:
        """Set callback for captured data."""
        self._callback = callback
    
    def validate_config(self, config: Dict) -> bool:
        """Validate configuration."""
        return "required_field" in config
    
    def get_name(self) -> str:
        return "custom_capture"
```

2. **Register Component**

```python
# In component_initializer.py
from opencontext.context_capture.custom_capture import CustomCapture

def initialize_capture_components(self, manager):
    # Existing components...
    
    # Add custom capture
    if self.config.get("capture", {}).get("custom", {}).get("enabled"):
        custom_capture = CustomCapture()
        manager.register_component("custom", custom_capture)
        custom_config = self.config.get("capture", {}).get("custom", {})
        manager.initialize_component("custom", custom_config)
```

3. **Add Configuration**

```yaml
# config/config.yaml
capture:
  custom:
    enabled: true
    required_field: value
```

### Adding a New Processor

1. **Create Processor**

```python
# opencontext/context_processing/processor/custom_processor.py
from opencontext.interfaces import IContextProcessor
from opencontext.models import RawContextProperties, ProcessedContext

class CustomProcessor(IContextProcessor):
    def __init__(self):
        self._statistics = {"processed": 0, "errors": 0}
    
    def process(self, context: RawContextProperties) -> bool:
        """Process the context."""
        try:
            # Processing logic
            processed = ProcessedContext(
                doc_id=context.object_id,
                title="Processed Title",
                content=context.content_text,
                # ... more fields
            )
            
            # Store or pass to next processor
            self._statistics["processed"] += 1
            return True
        except Exception as e:
            self._statistics["errors"] += 1
            return False
    
    def can_process(self, context: RawContextProperties) -> bool:
        """Check if this processor can handle the context."""
        return context.source == ContextSource.CUSTOM
    
    def get_name(self) -> str:
        return "custom_processor"
    
    def get_statistics(self) -> Dict:
        return self._statistics.copy()
    
    def reset_statistics(self) -> None:
        self._statistics = {"processed": 0, "errors": 0}
    
    def shutdown(self) -> None:
        pass
```

2. **Register Processor**

```python
# In component_initializer.py
from opencontext.context_processing.processor.custom_processor import CustomProcessor

def initialize_processors(self, manager, callback):
    # Existing processors...
    
    # Add custom processor
    custom_processor = CustomProcessor()
    manager.register_processor(custom_processor)
    
    # Update routing table
    manager._routing_table[ContextSource.CUSTOM] = "custom_processor"
```

### Adding a New Storage Backend

1. **Create Backend**

```python
# opencontext/storage/backends/custom_backend.py
from opencontext.storage.base_storage import IVectorStorageBackend

class CustomVectorBackend(IVectorStorageBackend):
    def initialize(self, config: Dict) -> bool:
        # Initialize connection
        return True
    
    def insert(self, doc_id: str, embedding: List[float], 
               metadata: Dict) -> bool:
        # Insert vector
        return True
    
    def search(self, query_embedding: List[float], top_k: int,
               filters: Dict) -> List[QueryResult]:
        # Search similar vectors
        return results
    
    def delete(self, doc_id: str) -> bool:
        # Delete vector
        return True
    
    # Implement other required methods...
```

2. **Register in Factory**

```python
# In unified_storage.py
class StorageBackendFactory:
    def __init__(self):
        self._backends = {
            StorageType.VECTOR_DB: {
                'chromadb': self._create_chromadb_backend,
                'custom': self._create_custom_backend,  # Add this
            }
        }
    
    def _create_custom_backend(self, config: Dict):
        from opencontext.storage.backends.custom_backend import CustomVectorBackend
        return CustomVectorBackend()
```

### Adding New API Endpoints

1. **Create Route File**

```python
# opencontext/server/routes/custom.py
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

router = APIRouter(tags=["custom"])

class CustomRequest(BaseModel):
    data: str

@router.post("/api/custom/endpoint")
async def custom_endpoint(request: CustomRequest):
    """Custom API endpoint."""
    try:
        # Process request
        result = process_data(request.data)
        return {"success": True, "result": result}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/api/custom/status")
async def custom_status():
    """Get custom component status."""
    return {"status": "ok"}
```

2. **Register Router**

```python
# In server/api.py
from .routes import custom

router.include_router(custom.router)
```

### Adding Agent Tools

1. **Create Tool**

```python
# opencontext/tools/custom_tools/custom_tool.py
from langchain.tools import BaseTool
from typing import Optional

class CustomTool(BaseTool):
    name = "custom_tool"
    description = "Performs a custom action"
    
    def _run(self, query: str) -> str:
        """Execute the tool."""
        # Implement tool logic
        return f"Result: {query}"
    
    async def _arun(self, query: str) -> str:
        """Async execution."""
        return self._run(query)
```

2. **Register Tool**

```python
# In tools/tool_definitions.py
from .custom_tools.custom_tool import CustomTool

AVAILABLE_TOOLS = [
    # Existing tools...
    CustomTool(),
]
```

## 🐛 Debugging

### Logging

```python
from opencontext.utils.logging_utils import get_logger

logger = get_logger(__name__)

logger.debug("Debug message")
logger.info("Info message")
logger.warning("Warning message")
logger.error("Error message")
logger.exception("Exception with traceback")
```

### Debug Mode

```bash
# Start with debug logging
python -m opencontext.cli start --debug

# Or set in config
```

```yaml
logging:
  level: DEBUG
```

### VS Code Configuration

```json
// .vscode/launch.json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Python: MineContext",
      "type": "python",
      "request": "launch",
      "module": "opencontext.cli",
      "args": ["start", "--config", "config/config.yaml"],
      "console": "integratedTerminal",
      "justMyCode": false
    }
  ]
}
```

## 📦 Building & Packaging

### Build Desktop App

```bash
# Using PyInstaller
bash build.sh
```

### Create Distribution

```bash
# Create wheel
python setup.py bdist_wheel

# Create source distribution
python setup.py sdist
```

## 📚 Documentation

### Adding Documentation

1. Create markdown file in `docs/`
2. Follow existing structure
3. Update `docs/README.md` with link
4. Include code examples

### Building API Docs (Future)

```bash
# Generate API documentation
pdoc opencontext --html --output-dir docs/api
```

## 🤝 Contributing

### Contribution Guidelines

1. **Code Quality**
   - Write tests for new features
   - Maintain >80% code coverage
   - Follow coding standards
   - Add docstrings

2. **Documentation**
   - Update relevant docs
   - Add inline comments for complex logic
   - Include examples

3. **Pull Requests**
   - Clear description
   - Reference related issues
   - Include screenshots for UI changes
   - Update CHANGELOG

4. **Code Review**
   - Address review comments
   - Keep changes focused
   - Rebase on main before merging

### Reporting Issues

**Bug Reports:**
- Clear title and description
- Steps to reproduce
- Expected vs actual behavior
- System information
- Log files

**Feature Requests:**
- Use case description
- Proposed solution
- Alternatives considered

## 📞 Getting Help

- **GitHub Discussions**: Ask questions
- **Discord**: Real-time chat
- **Email**: minecontext@bytedance.com

## 🔗 Related Resources

- [Architecture Overview](./03-architecture-overview.md)
- [API Reference](./06-api-reference.md)
- [Configuration Guide](./05-configuration-guide.md)
- [GitHub Repository](https://github.com/volcengine/MineContext)
