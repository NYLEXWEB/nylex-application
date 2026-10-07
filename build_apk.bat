@echo off
title NYLEX Release APK Builder
echo ===================================================
echo       NYLEX - Building Release APK
echo ===================================================
echo.

cd /d "%~dp0mobile"

echo Running: flutter build apk --release ...
call flutter build apk --release

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ---------------------------------------------------
    echo Build Successful! Copying to project release folder...
    echo ---------------------------------------------------
    if not exist "%~dp0release" mkdir "%~dp0release"
    copy /Y "%~dp0mobile\build\app\outputs\flutter-apk\app-release.apk" "%~dp0release\nylex-v1.0.0.apk"
    echo.
    echo ===================================================
    echo  COMPLETED! 
    echo  APK Location: "%~dp0release\nylex-v1.0.0.apk"
    echo ===================================================
) else (
    echo.
    echo [ERROR] Build failed. Please check the logs above.
)

pause
