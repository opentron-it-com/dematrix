@echo off
REM Set Java environment
set JAVA_HOME=C:\Users\ciorica\Documents\jdk-21.0.11
set PATH=%JAVA_HOME%\bin;%PATH%

REM Change to staging directory
cd /d C:\Users\ciorica\Documents\enterprise-doc-analyzer\staging

echo Starting Enterprise Document Analyzer Backend...
echo Java: %JAVA_HOME%
echo Working Directory: %CD%
echo.

REM Run backend with correct configuration
%JAVA_HOME%\bin\java ^
  -Dspring.profiles.active=dev ^
  -Dserver.port=8080 ^
  -Dspring.jpa.hibernate.ddl-auto=create-drop ^
  -Dspring.datasource.url=jdbc:h2:file:C:/Users/ciorica/Documents/enterprise-doc-analyzer/staging/data/h2/docdb;DB_CLOSE_DELAY=-1 ^
  -Dspring.datasource.driver-class-name=org.h2.Driver ^
  -Dspring.jpa.properties.hibernate.dialect=org.hibernate.dialect.H2Dialect ^
  -Dspring.datasource.username=sa ^
  -Dspring.datasource.password= ^
  -Dapp.ollama.base-url=http://127.0.0.1:11434 ^
  -Dapp.chroma.url=http://localhost:8000 ^
  -jar backend\enterprise-doc-analyzer-1.0.0.jar

pause
