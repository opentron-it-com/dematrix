@echo off
cd /d "C:\Users\ciorica\Documents\enterprise-doc-analyzer"
echo Building Electron app with backend JAR included...
call npm run build-win 2>&1 | findstr /r "."
pause
