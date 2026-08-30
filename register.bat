@echo off
:: PIME Portable - Registration Script
:: Auto-elevates to Administrator if needed

:: Check for admin rights
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Requesting Administrator privileges...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

echo ========================================
echo  PIME Portable - Register
echo ========================================
echo.

:: Get the directory where this script is located
set "PIME_DIR=%~dp0"
set "INSTALL_DIR=%ProgramFiles(x86)%\PIME"
cd /d "%PIME_DIR%"

echo Source: %PIME_DIR%
echo Target: %INSTALL_DIR%
echo.

:: Stop any existing PIMELauncher
echo Stopping any existing PIMELauncher...
taskkill /f /im PIMELauncher.exe >nul 2>&1
timeout /t 2 /nobreak >nul

:: Create target directory and copy files
echo Copying files to Program Files...
if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"
xcopy /E /Y /Q "%PIME_DIR%python" "%INSTALL_DIR%\python\" >nul
xcopy /E /Y /Q "%PIME_DIR%x86" "%INSTALL_DIR%\x86\" >nul
xcopy /E /Y /Q "%PIME_DIR%x64" "%INSTALL_DIR%\x64\" >nul
copy /Y "%PIME_DIR%PIMELauncher.exe" "%INSTALL_DIR%\" >nul
copy /Y "%PIME_DIR%backends.json" "%INSTALL_DIR%\" >nul
echo   [OK] Files copied

:: Set registry key
echo Setting PIME registry key...
reg add "HKLM\Software\PIME" /ve /d "%INSTALL_DIR%" /f >nul 2>&1
echo   [OK] Registry key set

:: Register 32-bit DLL
echo Registering 32-bit PIMETextService.dll...
"%SystemRoot%\System32\regsvr32.exe" /s "%INSTALL_DIR%\x86\PIMETextService.dll"
echo   [OK] 32-bit DLL registered

:: Register 64-bit DLL
echo Registering 64-bit PIMETextService.dll...
"%SystemRoot%\System32\regsvr32.exe" /s "%INSTALL_DIR%\x64\PIMETextService.dll"
echo   [OK] 64-bit DLL registered

:: Start PIMELauncher
echo Starting PIMELauncher...
start "" "%INSTALL_DIR%\PIMELauncher.exe"
echo   [OK] PIMELauncher started

:: Add PIMELauncher to Startup
echo Adding PIMELauncher to Startup...
set "STARTUP_FOLDER=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"
set "SHORTCUT=%STARTUP_FOLDER%\PIMELauncher.lnk"

:: Create shortcut using PowerShell
powershell -Command "$ws = New-Object -ComObject WScript.Shell; $s = $ws.CreateShortcut('%SHORTCUT%'); $s.TargetPath = '%INSTALL_DIR%\PIMELauncher.exe'; $s.WorkingDirectory = '%INSTALL_DIR%'; $s.Save()"
echo   [OK] Added to Startup folder

echo.
echo ========================================
echo  Registration complete!
echo  Files installed to: %INSTALL_DIR%
echo  PIMELauncher will auto-start on login.
echo  Press Win+Space to switch input methods.
echo ========================================
echo.
pause