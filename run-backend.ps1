# Set Java environment
$env:JAVA_HOME = "C:\Users\ciorica\Documents\jdk-21.0.11"
$env:PATH = "$env:JAVA_HOME\bin;$env:PATH"

# Change to staging directory
cd "C:\Users\ciorica\Documents\enterprise-doc-analyzer\staging"

Write-Host "Starting Enterprise Document Analyzer Backend..."
Write-Host "Java: $env:JAVA_HOME"
Write-Host "Working Directory: $(Get-Location)"
Write-Host ""

# Run backend with correct configuration
& "$env:JAVA_HOME\bin\java" `
  -Dspring.profiles.active=dev `
  -Dserver.port=8080 `
  -Dspring.jpa.hibernate.ddl-auto=create-drop `
  -Dspring.datasource.url="jdbc:h2:file:C:/Users/ciorica/Documents/enterprise-doc-analyzer/staging/data/h2/docdb;DB_CLOSE_DELAY=-1" `
  -Dspring.datasource.driver-class-name=org.h2.Driver `
  -Dspring.jpa.properties.hibernate.dialect=org.hibernate.dialect.H2Dialect `
  -Dspring.datasource.username=sa `
  -Dspring.datasource.password= `
  -Dapp.ollama.base-url=http://127.0.0.1:11434 `
  -Dapp.chroma.url=http://localhost:8000 `
  -jar backend/enterprise-doc-analyzer-1.0.0.jar
