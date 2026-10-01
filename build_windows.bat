@echo off
setlocal
cd /d "%~dp0"

echo.
echo ==========================================
echo   App UI Canvas - Windows Release Build
echo ==========================================
echo.

where flutter >nul 2>nul
if errorlevel 1 (
  echo [ERROR] Flutter wurde nicht in PATH gefunden.
  pause
  exit /b 1
)

if not exist "windows\" (
  echo [1/5] Windows-Host fehlt - wird erstellt...
  if exist "tool\bootstrap_platform_hosts.ps1" (
    powershell -NoProfile -File "tool\bootstrap_platform_hosts.ps1"
  ) else (
    call flutter create --platforms=windows .
  )
  if errorlevel 1 goto :failed
) else (
  echo [1/5] Windows-Host vorhanden.
)

echo.
echo [2/5] Pakete laden...
call flutter pub get
if errorlevel 1 goto :failed

echo.
echo [3/5] Code analysieren...
call flutter analyze --no-fatal-infos --no-fatal-warnings
if errorlevel 1 goto :failed

echo.
echo [4/5] Tests ausfuehren...
call flutter test
if errorlevel 1 goto :failed

echo.
echo [5/5] Windows Release bauen...
call flutter build windows --release
if errorlevel 1 goto :failed

echo.
echo ==========================================
echo   BUILD ERFOLGREICH
echo ==========================================
echo.
echo Ausgabe:
echo %CD%\build\windows\x64\runner\Release
echo.

if exist "build\windows\x64\runner\Release" (
  explorer "build\windows\x64\runner\Release"
)

pause
exit /b 0

:failed
echo.
echo ==========================================
echo   BUILD FEHLGESCHLAGEN
echo ==========================================
echo.
echo Siehe Fehlermeldung oben.
echo.
pause
exit /b 1
