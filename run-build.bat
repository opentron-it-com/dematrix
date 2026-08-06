@echo off
cd /d "C:\Users\ciorica\Documents\enterprise-doc-analyzer\frontend"
echo Building React application...
echo.
npm run build
echo.
echo Build complete. Checking output...
dir build
pause
