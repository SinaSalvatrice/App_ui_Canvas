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
  echo [1/6] Android-Host fehlt - wird erstellt...
  if exist "tool\bootstrap_platform_hosts.ps1" (
    powershell -NoProfile -File "tool\bootstrap_platform_hosts.ps1"
  ) else (
    call flutter create --platforms=android .
  )
  if errorlevel 1 goto :failed
) else (
  echo [1/6] Android-Host vorhanden.
)

powershell -NoProfile -ExecutionPolicy Bypass -File "tool\apply_app_icon.ps1" -Letter A
if errorlevel 1 goto :failed

echo.
echo [2/6] Pakete laden...
call flutter pub get
if errorlevel 1 goto :failed

echo.
echo [3/6] Code analysieren...
call flutter analyze --no-fatal-infos --no-fatal-warnings
if errorlevel 1 goto :failed

echo.
echo [4/6] Tests ausfuehren...
call flutter test
if errorlevel 1 goto :failed

echo.
echo [5/6] Android Build-Cache vorbereiten...
call :stop_gradle
call :clean_file_selector_cache
if errorlevel 1 (
  echo [WARN] Plugin-Cache blieb gesperrt - kompletter Build-Cache wird bereinigt.
  call :clean_all_build
  if errorlevel 1 goto :failed
)
call flutter pub get
if errorlevel 1 goto :failed

echo.
echo [6/6] Android Release APK bauen...
call flutter build apk --release
if not errorlevel 1 goto :build_ok

echo.
echo [WARN] Erster Release-Build fehlgeschlagen.
echo [WARN] Gradle wird gestoppt, der komplette Build-Cache geloescht
echo [WARN] und der Release-Build einmal automatisch wiederholt.
echo.
call :stop_gradle
call :clean_all_build
if errorlevel 1 goto :failed

call flutter pub get
if errorlevel 1 goto :failed

echo.
echo [RETRY] Android Release APK bauen...
call flutter build apk --release
if errorlevel 1 goto :failed

:build_ok
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

:stop_gradle
if exist "android\gradlew.bat" (
  pushd android
  call gradlew.bat --stop >nul 2>nul
  popd
)
exit /b 0

:clean_file_selector_cache
set "LOCKED_DIR=build\file_selector_android"
if not exist "%LOCKED_DIR%" exit /b 0

echo Entferne alten file_selector_android Build-Cache...
for /l %%I in (1,1,6) do (
  rmdir /s /q "%LOCKED_DIR%" >nul 2>nul
  if not exist "%LOCKED_DIR%" exit /b 0
  echo   Versuch %%I/6 - Ordner noch gesperrt, warte kurz...
  timeout /t 2 /nobreak >nul
)
exit /b 1

:clean_all_build
call :stop_gradle
if exist "build\" (
  echo Entferne kompletten Flutter Build-Cache...
  for /l %%I in (1,1,6) do (
    rmdir /s /q "build" >nul 2>nul
    if not exist "build\" exit /b 0
    echo   Versuch %%I/6 - Build-Ordner noch gesperrt, warte kurz...
    timeout /t 2 /nobreak >nul
  )
  echo [ERROR] Der Build-Ordner ist weiterhin von einem Prozess gesperrt.
  exit /b 1
)
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
