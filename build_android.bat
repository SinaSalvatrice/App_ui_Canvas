@echo off
setlocal
cd /d "%~dp0"

echo.
echo ==========================================
echo   App UI Canvas - Android Release Build
echo ==========================================
echo.

where flutter >nul 2>nul
if errorlevel 1 (
  echo [ERROR] Flutter wurde nicht in PATH gefunden.
  pause
  exit /b 1
)

if not exist "android\" (
  echo [1/5] Android-Host fehlt - wird erstellt...
  if exist "tool\bootstrap_platform_hosts.ps1" (
    powershell -NoProfile -File "tool\bootstrap_platform_hosts.ps1"
  ) else (
    call flutter create --platforms=android .
  )
  if errorlevel 1 goto :failed
) else (
  echo [1/5] Android-Host vorhanden.
)

powershell -NoProfile -ExecutionPolicy Bypass -File "tool\apply_app_icon.ps1" -Letter A
if errorlevel 1 goto :failed

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
echo [5/5] Android Release APK bauen...
call flutter build apk --release
if errorlevel 1 goto :failed

set "APK=build\app\outputs\flutter-apk\app-release.apk"

echo.
echo ==========================================
echo   BUILD ERFOLGREICH
echo ==========================================
echo.
echo APK:
echo %CD%\%APK%
echo.

if not exist "%APK%" goto :noapk

where adb >nul 2>nul
if errorlevel 1 goto :openfolder

set "ADB_DEVICE="
for /f "skip=1 tokens=1,2" %%A in ('adb devices') do (
  if "%%B"=="device" (
    if not defined ADB_DEVICE set "ADB_DEVICE=%%A"
  )
)

if not defined ADB_DEVICE goto :openfolder

echo Installiere auf %ADB_DEVICE% ...
adb -s "%ADB_DEVICE%" install -r "%APK%"
if errorlevel 1 goto :openfolder

echo Starte App UI Canvas auf %ADB_DEVICE% ...
adb -s "%ADB_DEVICE%" shell monkey -p dev.sinasalvatrice.app_ui_designer -c android.intent.category.LAUNCHER 1 >nul 2>nul

pause
exit /b 0

:openfolder
echo Kein verwendbares ADB-Geraet gefunden - oeffne APK-Ordner.
explorer "build\app\outputs\flutter-apk"
pause
exit /b 0

:noapk
echo [ERROR] APK wurde nach dem Build nicht gefunden.
goto :failed

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
