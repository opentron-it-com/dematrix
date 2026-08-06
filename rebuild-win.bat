@echo off
cd /d "C:\Users\ciorica\Documents\enterprise-doc-analyzer"
echo Building Windows installer with backend JAR...
call npm run build-win
pause
