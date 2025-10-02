# Windows Adaptation Guide for MineContext

## Executive Summary

This document provides a detailed implementation plan for adapting MineContext to run on Windows systems. The good news is that the core application is already largely cross-platform, requiring only script adaptations and minor enhancements for full Windows support.

## Current State Analysis

### ✅ Cross-Platform Components (Already Working)

1. **Core Application Code**
   - Python-based implementation is platform-independent
   - All Python dependencies in `requirements.txt` support Windows

2. **Screenshot Capture**
   - Uses `mss` library which is fully cross-platform
   - Supports Windows, macOS, and Linux out of the box
   - No code changes needed

3. **Storage & Processing**
   - File system operations use Python's `pathlib` and `os` modules
   - Database (ChromaDB) supports Windows
   - All processing logic is platform-agnostic

4. **Web Interface**
   - FastAPI server works on Windows
   - Static files and templates are platform-independent

### ⚠️ macOS-Specific Components (Need Adaptation)

1. **Build Script (`build.sh`)**
   - Bash script requires sh/bash interpreter
   - macOS code signing step only applies to macOS
   - **Status**: Needs Windows equivalent (`.bat` or PowerShell)

2. **Start Script (`start.sh`)**
   - Bash-based startup script
   - **Status**: Needs Windows equivalent (`.bat` or PowerShell)

3. **Documentation Examples**
   - Some documentation shows macOS-specific APIs (AppKit, Quartz)
   - These are for future features, not currently implemented
   - **Status**: Documentation only, no code impact

## Windows Adaptation Implementation Plan

### 1. Create Windows Build Script (`build.bat`)

**Purpose**: Provide Windows equivalent of `build.sh` for building the executable.

**Implementation**:
```batch
@echo off
REM OpenContext Build Script for Windows
REM Packages the project into a single executable using PyInstaller.

echo === OpenContext Build Script for Windows ===
echo.

REM 1. Dependency Check
echo --^> Checking for Python...
python --version >nul 2>&1
if errorlevel 1 (
    echo Error: Python is not found. Please install Python 3.
    exit /b 1
)

REM 2. Install dependencies from requirements.txt
echo --^> Installing dependencies from requirements.txt...
python -m pip install -r requirements.txt
if errorlevel 1 (
    echo Error: Failed to install dependencies
    exit /b 1
)

REM 3. Install PyInstaller if not present
echo --^> Checking for PyInstaller...
python -c "import PyInstaller" >nul 2>&1
if errorlevel 1 (
    echo --^> PyInstaller not found. Installing...
    python -m pip install pyinstaller
    if errorlevel 1 (
        echo Error: Failed to install PyInstaller
        exit /b 1
    )
)

REM 4. Clean up previous builds
echo --^> Cleaning up previous build directories...
if exist dist rmdir /s /q dist
if exist build rmdir /s /q build

REM 5. Run PyInstaller build
echo --^> Starting application build with PyInstaller...
pyinstaller --clean --noconfirm --log-level INFO opencontext.spec
if errorlevel 1 (
    echo Error: Build failed. Check the PyInstaller logs above for errors.
    exit /b 1
)

REM 6. Verify build and package
echo --^> Verifying build output...
if exist "dist\main.exe" (
    echo Build successful!
    echo.
    echo --^> Executable is available in the 'dist\' directory.
    dir dist
    echo.
    
    REM Copy config directory
    if exist config (
        echo --^> Copying 'config' directory to 'dist\'...
        xcopy /E /I /Y config dist\config
        echo Config directory copied.
    ) else (
        echo Warning: 'config' directory not found.
    )
    
    REM Create a start script for the packaged application
    echo --^> Creating start script in 'dist\'...
    (
        echo @echo off
        echo REM OpenContext Start Script for Windows
        echo.
        echo REM Get the directory where the script is located
        echo set SCRIPT_DIR=%%~dp0
        echo cd /d "%%SCRIPT_DIR%%"
        echo.
        echo REM --- Configuration ---
        echo REM Please replace 'your_api_key' with your actual API key before running.
        echo set CONTEXT_API_KEY=your_api_key
        echo.
        echo REM --- Start Application ---
        echo if exist "main.exe" ^(
        echo     echo Starting OpenContext...
        echo     main.exe start %%*
        echo ^) else ^(
        echo     echo Error: main.exe not found in the current directory.
        echo     exit /b 1
        echo ^)
    ) > dist\start.bat
    
    echo.
    echo === Build Complete ===
    echo.
    echo To run the application:
    echo    1. cd dist
    echo    2. Edit start.bat to set your CONTEXT_API_KEY
    echo    3. start.bat
    echo.
    echo Alternatively, run the executable directly:
    echo    dist\main.exe start
    echo    ^(Make sure to set the CONTEXT_API_KEY environment variable first^)
    echo.
) else (
    echo Error: Build failed. main.exe not found in dist directory.
    exit /b 1
)
```

**Key Features**:
- Uses Windows batch syntax (`@echo off`, `REM`, etc.)
- Uses `python` instead of `python3` (Windows convention)
- Uses Windows path separators (`\` instead of `/`)
- Uses Windows commands (`rmdir /s /q`, `xcopy`, `dir`)
- No macOS code signing (not needed on Windows)
- Creates `start.bat` instead of `start.sh`

### 2. Create Windows Start Script (`start.bat`)

**Purpose**: Provide simple way to start the application on Windows.

**Implementation**:
```batch
@echo off
REM OpenContext Start Script for Windows

REM Please replace 'your_api_key' with your actual API key
set CONTEXT_API_KEY=your_api_key

REM Set Python path to current directory
set PYTHONPATH=.

REM Start the application
python -m opencontext.cli start -c config\config.yaml
```

**Key Features**:
- Uses `set` for environment variables instead of `export`
- Uses backslash for paths (`config\config.yaml`)
- Uses `python` instead of `python3`

### 3. Update `.gitignore` for Windows

**Add Windows-specific entries**:
```
# Windows-specific
*.bat.bak
Thumbs.db
ehthumbs.db
Desktop.ini
```

### 4. Update Documentation

**Update `README.md`** to include Windows instructions:

```markdown
## 🚀 Quick Start

### Windows

1. **Download and Extract**
   - Download the latest release from [GitHub Releases]
   - Extract the ZIP file

2. **Run the Build Script**
   ```cmd
   build.bat
   ```

3. **Configure API Key**
   - Edit `dist\start.bat`
   - Replace `your_api_key` with your actual API key

4. **Start the Application**
   ```cmd
   cd dist
   start.bat
   ```

### macOS/Linux

[Existing instructions]
```

### 5. Optional Windows-Specific Enhancements

These are **not required** for basic functionality but can enhance the Windows experience:

#### 5.1 Windows Notification Support

**Current**: Uses console logging
**Enhancement**: Add Windows toast notifications

```python
# In opencontext/utils/notifications.py
import platform

def send_notification(title: str, message: str):
    if platform.system() == "Windows":
        try:
            from win10toast import ToastNotifier
            toaster = ToastNotifier()
            toaster.show_toast(title, message, duration=5)
        except ImportError:
            logger.warning("win10toast not installed, falling back to console")
            print(f"{title}: {message}")
    elif platform.system() == "Darwin":  # macOS
        # macOS notification code
        pass
    else:  # Linux
        # Linux notification code
        pass
```

**Dependencies**: Add to `requirements.txt`:
```
win10toast; platform_system == "Windows"
```

#### 5.2 Windows Active Window Detection

**Current**: Not implemented (documentation only)
**Enhancement**: Add Windows-specific window detection

```python
# In opencontext/utils/window_info.py
import platform

def get_active_window_info():
    """Get information about the active window."""
    if platform.system() == "Windows":
        try:
            import win32gui
            import win32process
            import psutil
            
            hwnd = win32gui.GetForegroundWindow()
            window_title = win32gui.GetWindowText(hwnd)
            _, pid = win32process.GetWindowThreadProcessId(hwnd)
            
            try:
                process = psutil.Process(pid)
                app_name = process.name()
            except:
                app_name = "Unknown"
            
            return {
                "window_title": window_title,
                "app_name": app_name,
                "pid": pid
            }
        except ImportError:
            return {"window_title": "", "app_name": ""}
    elif platform.system() == "Darwin":  # macOS
        # macOS implementation with AppKit/Quartz
        pass
    else:  # Linux
        # Linux implementation
        pass
```

**Dependencies**: Add to `requirements.txt`:
```
pywin32; platform_system == "Windows"
psutil
```

#### 5.3 Windows System Tray Icon

**Enhancement**: Add system tray icon for Windows

```python
# In opencontext/web/tray_icon.py (new file)
import platform

if platform.system() == "Windows":
    try:
        import pystray
        from PIL import Image
        
        class TrayIcon:
            def __init__(self):
                # Create tray icon
                image = Image.open("icon.png")
                menu = pystray.Menu(
                    pystray.MenuItem("Open Web UI", self.open_web_ui),
                    pystray.MenuItem("Exit", self.exit_app)
                )
                self.icon = pystray.Icon("MineContext", image, "MineContext", menu)
            
            def run(self):
                self.icon.run()
            
            def open_web_ui(self):
                import webbrowser
                webbrowser.open("http://localhost:8000")
            
            def exit_app(self):
                self.icon.stop()
    except ImportError:
        class TrayIcon:
            def __init__(self):
                pass
            def run(self):
                pass
```

**Dependencies**: Add to `requirements.txt`:
```
pystray; platform_system == "Windows"
```

### 6. Testing Plan

#### 6.1 Basic Functionality Testing

1. **Build Test**
   - Run `build.bat`
   - Verify `dist\main.exe` is created
   - Verify config files are copied

2. **Startup Test**
   - Set CONTEXT_API_KEY environment variable
   - Run `dist\main.exe start`
   - Verify web server starts on port 8000

3. **Screenshot Capture Test**
   - Configure screenshot capture in config.yaml
   - Start the application
   - Verify screenshots are captured to the configured directory
   - Verify screenshots are processed and stored

4. **Web Interface Test**
   - Open browser to http://localhost:8000
   - Verify UI loads correctly
   - Test search functionality
   - Test context browsing

#### 6.2 Windows-Specific Testing

1. **Path Handling**
   - Test with paths containing spaces
   - Test with UNC paths (\\\\server\\share)
   - Test with different drive letters (C:, D:, etc.)

2. **Permission Testing**
   - Test without administrator privileges
   - Test screenshot capture in restricted apps
   - Test file system operations

3. **Multi-Monitor Testing**
   - Test with single monitor
   - Test with multiple monitors
   - Verify correct monitor detection

## Compatibility Matrix

| Component | Windows | macOS | Linux | Notes |
|-----------|---------|-------|-------|-------|
| Core Application | ✅ | ✅ | ✅ | Python-based |
| Screenshot Capture | ✅ | ✅ | ✅ | Uses mss library |
| Build Script | ✅* | ✅ | ✅ | *Requires build.bat |
| Start Script | ✅* | ✅ | ✅ | *Requires start.bat |
| Web Interface | ✅ | ✅ | ✅ | FastAPI-based |
| Storage | ✅ | ✅ | ✅ | ChromaDB, SQLite |
| Window Detection | 🔶 | 🔶 | 🔶 | Optional feature |
| Notifications | 🔶 | 🔶 | 🔶 | Optional feature |

Legend:
- ✅ Full support
- 🔶 Optional/Partial support
- ❌ Not supported

## Migration Path for Existing Users

### From macOS to Windows

1. **Export Data**
   - Copy the entire data directory
   - Copy configuration files

2. **Install on Windows**
   - Download Windows version
   - Run `build.bat`
   - Copy data directory to new location

3. **Update Paths**
   - Update paths in `config\config.yaml` to use Windows format
   - Update API keys if needed

4. **Verify**
   - Start application
   - Verify data is accessible
   - Test search functionality

## Troubleshooting

### Common Issues

1. **"Python not found" Error**
   - Solution: Add Python to PATH during installation
   - Verify: Run `python --version` in Command Prompt

2. **"Module not found" Errors**
   - Solution: Run `python -m pip install -r requirements.txt`
   - Ensure you're using the correct Python environment

3. **Permission Errors**
   - Solution: Run Command Prompt as Administrator
   - Check file/folder permissions

4. **Screenshot Capture Not Working**
   - Solution: Ensure mss library is installed: `pip install mss`
   - Check screen resolution and monitor configuration

5. **Build Fails with PyInstaller**
   - Solution: Update PyInstaller: `pip install --upgrade pyinstaller`
   - Clear build cache: Delete `build` and `dist` folders

## Performance Considerations

### Windows-Specific Optimizations

1. **Antivirus Exclusions**
   - Add MineContext directory to Windows Defender exclusions
   - Prevents performance degradation during file operations

2. **Power Settings**
   - Use "High Performance" power plan for best results
   - Prevents CPU throttling during capture

3. **Disk I/O**
   - Use SSD for data directory if possible
   - Configure Windows Search to exclude data directory

## Security Considerations

### Windows-Specific Security

1. **Code Signing**
   - Consider signing the executable for distribution
   - Reduces "Unknown Publisher" warnings

2. **Permissions**
   - Application runs with user-level permissions
   - No administrator rights required for normal operation

3. **Firewall**
   - Windows Firewall may prompt for network access
   - Allow access for web interface (localhost only)

4. **Data Storage**
   - Screenshots stored in user-specified directory
   - Use Windows encryption (BitLocker) for sensitive data

## Conclusion

MineContext is **already largely compatible with Windows** due to its Python-based architecture and use of cross-platform libraries. The main adaptations needed are:

1. **Essential** (Required for Windows support):
   - Windows build script (`build.bat`) ✅
   - Windows start script (`start.bat`) ✅

2. **Optional** (Enhances Windows experience):
   - Windows-specific window detection
   - Windows notifications
   - System tray integration

The core functionality—screenshot capture, processing, storage, and web interface—works on Windows without any code modifications.

## References

- [Python Windows Guide](https://docs.python.org/3/using/windows.html)
- [PyInstaller Windows Notes](https://pyinstaller.readthedocs.io/en/stable/usage.html#windows)
- [mss Library Documentation](https://python-mss.readthedocs.io/)
- [FastAPI Deployment](https://fastapi.tiangolo.com/deployment/)
