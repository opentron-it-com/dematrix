$ports=@(80,8080,11434,8000,5432,3000)
$pids=@()
foreach ($p in $ports) {
    try { $conns=Get-NetTCPConnection -LocalPort $p -ErrorAction SilentlyContinue } catch { $conns=$null }
    if ($conns) { $pids += $conns | Select-Object -Expand OwningProcess }
}
$pids = $pids | Sort-Object -Unique | Where-Object { $_ -and $_ -ne $PID -and $_ -ne 0 }
if (-not $pids) { Write-Host 'No conflicting PIDs found.'; exit 0 }
Write-Host 'Attempting to kill PIDs:' ($pids -join ', ')
foreach ($targetPid in $pids) {
    try {
        taskkill /PID $targetPid /F | Out-Host
    } catch {
        Write-Host "Failed to kill PID $targetPid"
    }
}
