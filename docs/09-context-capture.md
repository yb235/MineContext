# Context Capture Documentation

This document details MineContext's context capture system and how to work with capture components.

## 📸 Capture System Overview

The capture system is responsible for collecting raw context from various sources:

```
┌─────────────────────────────────────────────────────┐
│          Capture Manager                             │
│  (opencontext/managers/capture_manager.py)          │
└──────────────┬──────────────────────────────────────┘
               │
               ├─── Registers & Manages
               │
       ┌───────┴────────┬────────────┬─────────────┐
       │                │            │             │
       ▼                ▼            ▼             ▼
┌──────────────┐ ┌─────────┐ ┌──────────┐  ┌──────────┐
│ Screenshot   │ │Document │ │  File    │  │  Custom  │
│  Capture     │ │ Monitor │ │ Upload   │  │  Source  │
└──────────────┘ └─────────┘ └──────────┘  └──────────┘
       │                │            │             │
       └────────────────┴────────────┴─────────────┘
                        │
                        ▼
            ┌──────────────────────┐
            │ RawContextProperties │
            └──────────────────────┘
                        │
                        ▼
                Processing Pipeline
```

## 🎯 Capture Components

### 1. Screenshot Capture (`screenshot.py`)

Captures screen content at regular intervals.

**Features:**
- Multi-monitor support
- Configurable capture interval
- Application filtering
- Automatic compression
- Metadata extraction

**Configuration:**
```yaml
capture:
  screenshot:
    enabled: true
    capture_interval: 5  # seconds
    save_path: ./screenshots
    image_format: png    # png or jpg
    quality: 85          # for jpg
    max_size: 1920x1080  # resize if larger
    monitors: []         # empty = all, or [0, 1, ...]
    exclude_apps:
      - "1Password"
      - "Banking App"
```

**Implementation Details:**

```python
# opencontext/context_capture/screenshot.py
class ScreenshotCapture(ICaptureComponent):
    def __init__(self):
        self._config = {}
        self._running = False
        self._callback = None
        self._capture_thread = None
    
    def initialize(self, config: Dict) -> bool:
        """Initialize capture component."""
        self._config = config
        self.interval = config.get("capture_interval", 5)
        self.save_path = Path(config.get("save_path", "./screenshots"))
        self.save_path.mkdir(parents=True, exist_ok=True)
        return True
    
    def start(self) -> bool:
        """Start periodic capture."""
        if self._running:
            return True
        
        self._running = True
        self._capture_thread = threading.Thread(
            target=self._capture_loop,
            daemon=True
        )
        self._capture_thread.start()
        return True
    
    def _capture_loop(self):
        """Main capture loop."""
        while self._running:
            try:
                contexts = self.capture()
                if contexts and self._callback:
                    self._callback(contexts)
            except Exception as e:
                logger.error(f"Capture error: {e}")
            
            time.sleep(self.interval)
    
    def capture(self) -> List[RawContextProperties]:
        """Perform single capture."""
        screenshots = []
        
        # Get monitors to capture
        monitors = self._get_monitors_to_capture()
        
        for monitor in monitors:
            # Check if should exclude current app
            active_app = self._get_active_application()
            if self._should_exclude_app(active_app):
                continue
            
            # Capture screenshot
            image = self._capture_monitor(monitor)
            
            # Save to file
            timestamp = datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
            filename = f"{timestamp}_monitor_{monitor}.{self.image_format}"
            filepath = self.save_path / filename
            
            # Compress and save
            self._save_image(image, filepath)
            
            # Create context
            context = RawContextProperties(
                source=ContextSource.SCREENSHOT,
                content_format=ContentFormat.IMAGE,
                content_path=str(filepath),
                create_time=datetime.now(),
                additional_info={
                    "window": self._get_active_window(),
                    "app": active_app,
                    "monitor": monitor
                }
            )
            screenshots.append(context)
        
        return screenshots
    
    def _capture_monitor(self, monitor_index: int) -> Image:
        """Capture specific monitor."""
        import pyautogui
        
        # Get monitor info
        monitors = pyautogui.get_monitors()
        if monitor_index >= len(monitors):
            return None
        
        monitor = monitors[monitor_index]
        
        # Capture
        screenshot = pyautogui.screenshot(
            region=(
                monitor['left'],
                monitor['top'],
                monitor['width'],
                monitor['height']
            )
        )
        
        return screenshot
    
    def _save_image(self, image: Image, filepath: Path):
        """Save and optionally compress image."""
        # Resize if needed
        if self._config.get("max_size"):
            max_w, max_h = map(int, self._config["max_size"].split("x"))
            if image.width > max_w or image.height > max_h:
                image.thumbnail((max_w, max_h), Image.LANCZOS)
        
        # Save
        if self.image_format == "jpg":
            quality = self._config.get("quality", 85)
            image.save(filepath, "JPEG", quality=quality, optimize=True)
        else:
            image.save(filepath, "PNG", optimize=True)
```

**Platform-Specific Features:**

**macOS:**
```python
def _get_active_application(self) -> str:
    """Get active application on macOS."""
    import AppKit
    workspace = AppKit.NSWorkspace.sharedWorkspace()
    active_app = workspace.activeApplication()
    return active_app['NSApplicationName']

def _get_active_window(self) -> str:
    """Get active window title."""
    import Quartz
    window_list = Quartz.CGWindowListCopyWindowInfo(
        Quartz.kCGWindowListOptionOnScreenOnly,
        Quartz.kCGNullWindowID
    )
    for window in window_list:
        if window.get('kCGWindowOwnerName'):
            return window.get('kCGWindowName', '')
```

**Windows:**
```python
def _get_active_application(self) -> str:
    """Get active application on Windows."""
    import win32gui
    import win32process
    
    hwnd = win32gui.GetForegroundWindow()
    _, pid = win32process.GetWindowThreadProcessId(hwnd)
    # Get process name from PID
    return get_process_name(pid)
```

### 2. Document Monitor (`vault_document_monitor.py`)

Watches file system for document changes.

**Features:**
- Watches multiple directories
- File pattern matching
- Change detection (new, modified, deleted)
- Debouncing to avoid duplicate captures

**Configuration:**
```yaml
capture:
  document:
    enabled: true
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
```

**Implementation:**

```python
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler

class DocumentMonitor(ICaptureComponent, FileSystemEventHandler):
    def __init__(self):
        self._observer = None
        self._debounce = {}  # Path -> last_modified_time
    
    def initialize(self, config: Dict) -> bool:
        """Initialize file watcher."""
        self._config = config
        self._observer = Observer()
        
        # Set up watched paths
        for path in config.get("watch_paths", []):
            self._observer.schedule(
                self,
                path=os.path.expanduser(path),
                recursive=True
            )
        
        return True
    
    def start(self) -> bool:
        """Start watching."""
        self._observer.start()
        return True
    
    def on_modified(self, event):
        """Handle file modification."""
        if event.is_directory:
            return
        
        # Check if file matches patterns
        if not self._matches_patterns(event.src_path):
            return
        
        # Debounce: only process if enough time has passed
        if not self._should_process(event.src_path):
            return
        
        # Create context
        context = self._create_context_from_file(event.src_path)
        
        # Call callback
        if self._callback and context:
            self._callback([context])
    
    def _matches_patterns(self, filepath: str) -> bool:
        """Check if file matches include/exclude patterns."""
        from fnmatch import fnmatch
        
        # Check ignore patterns first
        for pattern in self._config.get("ignore_patterns", []):
            if fnmatch(filepath, pattern):
                return False
        
        # Check file patterns
        for pattern in self._config.get("file_patterns", []):
            if fnmatch(filepath, pattern):
                return True
        
        return False
    
    def _should_process(self, filepath: str) -> bool:
        """Check if enough time has passed to process file."""
        now = time.time()
        last_time = self._debounce.get(filepath, 0)
        
        if now - last_time < 5:  # 5 second debounce
            return False
        
        self._debounce[filepath] = now
        return True
    
    def _create_context_from_file(self, filepath: str) -> RawContextProperties:
        """Create context from file."""
        # Read file content (for text files)
        if filepath.endswith(('.md', '.txt')):
            with open(filepath, 'r', encoding='utf-8') as f:
                content = f.read()
            
            return RawContextProperties(
                source=ContextSource.FILE,
                content_format=ContentFormat.TEXT,
                content_text=content,
                content_path=filepath,
                create_time=datetime.fromtimestamp(
                    os.path.getmtime(filepath)
                ),
                additional_info={
                    "filename": os.path.basename(filepath),
                    "extension": os.path.splitext(filepath)[1],
                    "size": os.path.getsize(filepath)
                }
            )
        else:
            # For binary files (PDF, etc.), store path only
            return RawContextProperties(
                source=ContextSource.FILE,
                content_format=ContentFormat.DOCUMENT,
                content_path=filepath,
                create_time=datetime.fromtimestamp(
                    os.path.getmtime(filepath)
                ),
                additional_info={
                    "filename": os.path.basename(filepath),
                    "extension": os.path.splitext(filepath)[1],
                    "size": os.path.getsize(filepath)
                }
            )
```

### 3. Manual Upload

User-initiated content capture via API.

**API Endpoint:**
```python
# opencontext/server/routes/vaults.py
@router.post("/api/vaults/create")
async def create_document(document: VaultDocument):
    """Create document from user input."""
    # Create context
    context = RawContextProperties(
        source=ContextSource.VAULT,
        content_format=ContentFormat.TEXT,
        content_text=document.content,
        create_time=datetime.now(),
        additional_info={
            "title": document.title,
            "document_type": document.document_type,
            "tags": document.tags
        }
    )
    
    # Process
    processor_manager.process(context)
    
    return {"success": True}
```

## 🔧 Capture Manager

The Capture Manager coordinates all capture components.

**Key Methods:**

```python
class ContextCaptureManager:
    def register_component(self, name: str, component: ICaptureComponent) -> bool:
        """Register a new capture component."""
        
    def initialize_component(self, name: str, config: Dict) -> bool:
        """Initialize component with configuration."""
        
    def start_component(self, name: str) -> bool:
        """Start a specific component."""
        
    def stop_component(self, name: str, graceful: bool = True) -> bool:
        """Stop a specific component."""
        
    def start_all_components(self) -> Dict[str, bool]:
        """Start all registered components."""
        
    def capture(self, component_name: str) -> List[RawContextProperties]:
        """Manually trigger capture from specific component."""
        
    def set_callback(self, callback: Callable) -> None:
        """Set callback for captured data."""
```

**Usage Example:**

```python
# Initialize manager
capture_manager = ContextCaptureManager()

# Register components
screenshot_capture = ScreenshotCapture()
capture_manager.register_component("screenshot", screenshot_capture)

document_monitor = DocumentMonitor()
capture_manager.register_component("document", document_monitor)

# Configure
screenshot_config = {
    "enabled": True,
    "capture_interval": 5,
    "save_path": "./screenshots"
}
capture_manager.initialize_component("screenshot", screenshot_config)

# Set callback
def on_capture(contexts: List[RawContextProperties]):
    print(f"Captured {len(contexts)} contexts")
    # Process contexts
    
capture_manager.set_callback(on_capture)

# Start all
capture_manager.start_all_components()
```

## 📊 Capture Statistics

The manager tracks statistics for each component:

```python
stats = capture_manager.get_statistics()
# Returns:
{
    "total_captures": 1000,
    "total_contexts_captured": 5000,
    "last_capture_time": "2025-01-01T12:00:00",
    "errors": 5,
    "components": {
        "screenshot": {
            "captures": 800,
            "contexts_captured": 4000,
            "errors": 2,
            "last_capture_time": "2025-01-01T12:00:00"
        },
        "document": {
            "captures": 200,
            "contexts_captured": 1000,
            "errors": 3,
            "last_capture_time": "2025-01-01T11:59:00"
        }
    }
}
```

## 🎨 Creating Custom Capture Components

### Step 1: Implement Interface

```python
from opencontext.interfaces import ICaptureComponent

class CustomCapture(ICaptureComponent):
    def initialize(self, config: Dict) -> bool:
        """Initialize component."""
        pass
    
    def start(self) -> bool:
        """Start capturing."""
        pass
    
    def stop(self, graceful: bool = True) -> bool:
        """Stop capturing."""
        pass
    
    def capture(self) -> List[RawContextProperties]:
        """Perform capture."""
        pass
    
    def set_callback(self, callback: Callable) -> None:
        """Set callback."""
        pass
    
    def validate_config(self, config: Dict) -> bool:
        """Validate configuration."""
        pass
    
    def get_name(self) -> str:
        return "custom_capture"
```

### Step 2: Register Component

```python
# In component_initializer.py
custom_capture = CustomCapture()
capture_manager.register_component("custom", custom_capture)
```

### Step 3: Configure

```yaml
# config/config.yaml
capture:
  custom:
    enabled: true
    custom_option: value
```

## 🔒 Privacy & Security

### Application Exclusion

```python
def _should_exclude_app(self, app_name: str) -> bool:
    """Check if application should be excluded."""
    excluded = self._config.get("exclude_apps", [])
    return app_name in excluded
```

### Content Filtering

```python
def _filter_sensitive_content(self, content: str) -> str:
    """Remove sensitive information."""
    import re
    
    # Filter credit card numbers
    content = re.sub(r'\d{4}[-\s]?\d{4}[-\s]?\d{4}[-\s]?\d{4}', '[CARD]', content)
    
    # Filter SSN
    content = re.sub(r'\d{3}-\d{2}-\d{4}', '[SSN]', content)
    
    # Filter passwords (basic)
    content = re.sub(r'password[:\s]+\S+', 'password: [FILTERED]', content, flags=re.IGNORECASE)
    
    return content
```

### Temporary Pause

```python
# Pause capture temporarily
capture_manager.stop_component("screenshot")

# Resume
capture_manager.start_component("screenshot")
```

## 🚀 Performance Optimization

### Image Compression

```python
def _optimize_screenshot(self, image: Image) -> Image:
    """Optimize screenshot size."""
    # Resize if too large
    max_width, max_height = 1920, 1080
    if image.width > max_width or image.height > max_height:
        image.thumbnail((max_width, max_height), Image.LANCZOS)
    
    # Convert to RGB if needed (removes alpha channel)
    if image.mode in ('RGBA', 'LA'):
        background = Image.new('RGB', image.size, (255, 255, 255))
        background.paste(image, mask=image.split()[-1])
        image = background
    
    return image
```

### Batch Processing

```python
def _batch_capture(self) -> List[RawContextProperties]:
    """Capture multiple sources in batch."""
    contexts = []
    
    # Capture all monitors
    with concurrent.futures.ThreadPoolExecutor(max_workers=3) as executor:
        futures = [
            executor.submit(self._capture_monitor, i)
            for i in range(len(self.monitors))
        ]
        
        for future in concurrent.futures.as_completed(futures):
            context = future.result()
            if context:
                contexts.append(context)
    
    return contexts
```

### Async Callbacks

```python
async def _async_callback(self, contexts: List[RawContextProperties]):
    """Async callback processing."""
    # Non-blocking processing
    tasks = [self._process_context(ctx) for ctx in contexts]
    await asyncio.gather(*tasks)
```

## 📚 Related Documentation

- [Architecture Overview](./03-architecture-overview.md)
- [Data Flow & Workflow](./04-data-flow-workflow.md)
- [Configuration Guide](./05-configuration-guide.md)
- [Development Guide](./12-development-guide.md)
