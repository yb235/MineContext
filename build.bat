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
    echo ✅ Build successful!
    echo.
    echo --^> Executable is available in the 'dist\' directory.
    dir dist
    echo.
    
    REM Copy config directory
    if exist config (
        echo --^> Copying 'config' directory to 'dist\'...
        xcopy /E /I /Y config dist\config >nul 2>&1
        echo ✅ Config directory copied.
    ) else (
        echo ⚠️ Warning: 'config' directory not found.
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
        echo     echo ❌ Error: main.exe not found in the current directory.
        echo     exit /b 1
        echo ^)
    ) > dist\start.bat
    
    echo ✅ Start script created.
    echo.
    echo === Build Complete ===
    echo.
    echo 🚀 To run the application:
    echo    1. cd dist
    echo    2. Edit start.bat to set your CONTEXT_API_KEY
    echo    3. start.bat
    echo.
    echo Alternatively, run the executable directly:
    echo    dist\main.exe start
    echo    ^(Make sure to set the CONTEXT_API_KEY environment variable first^)
    echo.
) else (
    echo ❌ Error: Build failed. main.exe not found in dist directory.
    exit /b 1
)
