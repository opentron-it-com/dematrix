@echo off
cd /d "C:\Users\ciorica\Documents\enterprise-doc-analyzer"
echo Running electron-builder directly...
REM Skip the react build, go straight to electron-builder
call npx electron-builder --win --publish never
pause
