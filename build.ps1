# Set Java environment
$env:JAVA_HOME = "C:\Users\ciorica\Documents\jdk-21.0.11"
$env:PATH = "$env:JAVA_HOME\bin;$env:PATH"

# Verify Java is available
Write-Host "Java version:"
& "$env:JAVA_HOME\bin\java" -version

# Change to project directory
cd "C:\Users\ciorica\Documents\enterprise-doc-analyzer"

# Run Maven build
Write-Host "Building with Maven..."
& "C:\Users\ciorica\Documents\apache-maven-3.9.16\bin\mvn.cmd" clean package -DskipTests -X

if ($LASTEXITCODE -eq 0) {
    Write-Host "Build successful!"
    Write-Host "Copying JAR to staging..."
    Copy-Item "target/enterprise-doc-analyzer-1.0.0.jar" -Destination "staging/backend/enterprise-doc-analyzer-1.0.0.jar" -Force
    Write-Host "Done!"
} else {
    Write-Host "Build failed!"
    exit 1
}
