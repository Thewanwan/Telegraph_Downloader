@echo off
cd /d "%~dp0"
echo Current directory: %CD%
echo.
echo [1/3] Checking Python...
python --version
if %errorlevel% neq 0 (
    echo ERROR: Python not found. Please install Python from python.org
    pause
    exit /b 1
)
echo.
echo [2/3] Installing PyInstaller...
pip install pyinstaller
echo.
echo [3/3] Building EXE...
pyinstaller --onefile --name "TelegraphDownloader" --windowed --clean --noconfirm "%~dp0Telegraph_downloader.py"
echo.
if exist "%~dp0dist\TelegraphDownloader.exe" (
    echo [OK] SUCCESS: dist\TelegraphDownloader.exe
) else (
    echo [FAIL] Build failed. Check errors above.
)
pause
