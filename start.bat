@echo off
REM OpenContext Start Script for Windows

REM Please replace 'your_api_key' with your actual API key
set CONTEXT_API_KEY=your_api_key

REM Set Python path to current directory
set PYTHONPATH=.

REM Start the application
python -m opencontext.cli start -c config\config.yaml
