$pattern=':80|:8080|:11434|:8000|:5432'
$lines = netstat -ano | Select-String $pattern
Write-Host "Netstat matches:"
$lines | ForEach-Object { Write-Host $_ }
$pids = $lines | ForEach-Object { ($_ -split '\s+')[-1] } | Sort-Object -Unique
foreach ($ppid in $pids) {
    if ($ppid) {
        Write-Host "PID=$ppid"
        tasklist /FI "PID eq $ppid"
    }
}

Write-Host "--- staging/logs/backend.log ---"
if (Test-Path "staging\logs\backend.log") { Get-Content "staging\logs\backend.log" -Tail 120 } else { Write-Host 'backend.log not found' }

Write-Host "--- staging/logs/nginx.log ---"
if (Test-Path "staging\logs\nginx.log") { Get-Content "staging\logs\nginx.log" -Tail 60 } else { Write-Host 'nginx.log not found' }

Write-Host "--- staging/logs/ollama.log ---"
if (Test-Path "staging\logs\ollama.log") { Get-Content "staging\logs\ollama.log" -Tail 60 } else { Write-Host 'ollama.log not found' }

Write-Host "--- staging/logs/chroma.log ---"
if (Test-Path "staging\logs\chroma.log") { Get-Content "staging\logs\chroma.log" -Tail 60 } else { Write-Host 'chroma.log not found' }
