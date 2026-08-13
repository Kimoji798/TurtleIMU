@echo off
title TurtleIMU Server
cd /d "%~dp0"

where node >nul 2>nul
if errorlevel 1 (
  echo [ERROR] Node.js not found. Install: https://nodejs.org
  pause
  exit /b 1
)

echo.
echo ==============================================
echo   TurtleIMU Test Server
echo   Phone must use the SAME WiFi as this PC
echo   Open the Phone URL below on your phone
echo   Close this window = stop server
echo ==============================================
echo.

node server.js %*

echo.
echo Server stopped.
if "%~1"=="" pause