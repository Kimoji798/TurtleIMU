@echo off
title TTimu Deploy
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0deploy.ps1" %*