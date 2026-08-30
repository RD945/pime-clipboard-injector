@echo off
:: PIME Portable - Unregistration Script
:: Auto-elevates to Administrator if needed

:: Check for admin rights
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Requesting Administrator privileges...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

echo ========================================
echo  PIME Portable - Unregister
echo ========================================
echo.

set "INSTALL_DIR=%ProgramFiles(x86)%\PIME"

echo Removing PIME from: %INSTALL_DIR%
echo.

:: Stop PIMELauncher
echo Stopping PIMELauncher...
taskkill /f /im PIMELauncher.exe >nul 2>&1
timeout /t 2 /nobreak >nul
echo   [OK] PIMELauncher stopped

:: Unregister 32-bit DLL
echo Unregistering 32-bit PIMETextService.dll...
"%SystemRoot%\System32\regsvr32.exe" /u /s "%INSTALL_DIR%\x86\PIMETextService.dll"
echo   [OK] 32-bit DLL unregistered

:: Unregister 64-bit DLL
echo Unregistering 64-bit PIMETextService.dll...
"%SystemRoot%\System32\regsvr32.exe" /u /s "%INSTALL_DIR%\x64\PIMETextService.dll"
echo   [OK] 64-bit DLL unregistered

:: Remove registry key
echo Removing PIME registry key...
reg delete "HKLM\Software\PIME" /f >nul 2>&1
echo   [OK] Registry key removed

:: Remove from Startup
echo Removing from Startup...
set "SHORTCUT=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\PIMELauncher.lnk"
if exist "%SHORTCUT%" del /f "%SHORTCUT%"
echo   [OK] Removed from Startup folder

:: Delete installed files
echo Removing installed files...
rmdir /S /Q "%INSTALL_DIR%" >nul 2>&1
echo   [OK] Files removed

echo.
echo ========================================
echo  Unregistration complete!
echo  PIME has been completely removed.
echo ========================================
echo.
pause
