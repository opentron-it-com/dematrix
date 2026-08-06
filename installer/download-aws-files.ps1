param(
    [Parameter(Mandatory=$true)]
    [string]$Manifest,

    [Parameter(Mandatory=$true)]
    [string]$TargetDir
)

function Write-Log {
    param([string]$Message)
    Write-Host $Message
}

if (-not (Test-Path $Manifest)) {
    Write-Log "ERROR: Manifest file not found: $Manifest"
    exit 1
}

$manifestData = Get-Content $Manifest -Raw | ConvertFrom-Json

$TargetDir = $TargetDir.Trim('"')
if ([string]::IsNullOrWhiteSpace($TargetDir)) {
    Write-Log "ERROR: TargetDir parameter is empty or invalid."
    exit 1
}
$TargetDir = $TargetDir.TrimEnd('\')
$TargetDir = [System.IO.Path]::GetFullPath($TargetDir)
if (-not (Test-Path $TargetDir)) {
    New-Item -Path $TargetDir -ItemType Directory -Force | Out-Null
}

Write-Log "Target directory: $TargetDir"

function Get-DirectDownloadUrl {
    param([string]$Url)
    if ($Url -match '[\?&]web=1') {
        return ($Url -replace '([\?&])web=1', '$1download=1')
    }
    return $Url
}

function Download-FileWithProgress {
    param(
        [Parameter(Mandatory=$true)][string]$Url,
        [Parameter(Mandatory=$true)][string]$Destination,
        [Parameter(Mandatory=$true)][string]$Name
    )

    Write-Log "Downloading from AWS: $Name"
    
    try {
        # Stream download buffer to calculate progress continuously
        $request = [System.Net.HttpWebRequest]::Create($Url)
        $request.UserAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'
        $request.Timeout = 3600000 # 1 hour timeout for large images
        
        $response = $request.GetResponse()
        $totalBytes = $response.ContentLength
        $responseStream = $response.GetResponseStream()
        $targetStream = [System.IO.File]::Create($Destination)

        $buffer = New-Object byte[] 65536 # 64KB buffer
        $downloadedBytes = 0
        $lastPercent = -1

        while (($bytesRead = $responseStream.Read($buffer, 0, $buffer.Length)) -gt 0) {
            $targetStream.Write($buffer, 0, $bytesRead)
            $downloadedBytes += $bytesRead

            if ($totalBytes -gt 0) {
                $percent = [math]::Floor(($downloadedBytes / $totalBytes) * 100)
                if ($percent -ne $lastPercent) {
                    $mbDownloaded = [math]::Round($downloadedBytes / 1MB, 2)
                    $mbTotal = [math]::Round($totalBytes / 1MB, 2)
                    
                    Write-Progress -Activity "Downloading $Name" `
                                   -Status "$mbDownloaded MB / $mbTotal MB ($percent%)" `
                                   -PercentComplete $percent
                    $lastPercent = $percent
                }
            } else {
                $mbDownloaded = [math]::Round($downloadedBytes / 1MB, 2)
                Write-Progress -Activity "Downloading $Name" `
                               -Status "$mbDownloaded MB downloaded..." `
                               -PercentComplete -1
            }
        }
        
        Write-Progress -Activity "Downloading $Name" -Status "Completed" -Completed
        return
    }
    catch {
        Write-Log "WARNING: Streamed download with progress failed: $_"
    }
    finally {
        if ($null -ne $targetStream) { $targetStream.Close(); $targetStream.Dispose() }
        if ($null -ne $responseStream) { $responseStream.Close(); $responseStream.Dispose() }
        if ($null -ne $response) { $response.Close() }
    }

    # Fallback method using standard WebClient
    try {
        Write-Log "Falling back to standard WebClient download..."
        $webClient = New-Object System.Net.WebClient
        $webClient.Headers.Add('User-Agent', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)')
        $webClient.DownloadFile($Url, $Destination)
        return
    }
    catch {
        Write-Log "WARNING: WebClient download failed: $_"
    }

    throw "Unable to download $Name from $Url"
}

$files = @()
if ($manifestData.dockerEngine) {
    $files += [PSCustomObject]@{
        fileName = $manifestData.dockerEngine.fileName
        sharePointUrl = $manifestData.dockerEngine.sharePointUrl
        type = 'engine'
    }
}
if ($manifestData.dockerImages) {
    foreach ($image in $manifestData.dockerImages) {
        $files += [PSCustomObject]@{
            fileName = $image.fileName
            sharePointUrl = $image.sharePointUrl
            type = 'image'
        }
    }
}

$engineDir = Join-Path $TargetDir 'docker-engine'
$imageDir = Join-Path $TargetDir 'docker-images'
New-Item -Path $imageDir -ItemType Directory -Force | Out-Null

foreach ($entry in $files) {
    if ($entry.type -eq 'engine') {
        $engineExe = Join-Path $engineDir 'dockerd.exe'
        if (Test-Path $engineExe) {
            Write-Log "Docker engine already extracted: $engineExe"
            continue
        }

        New-Item -Path $engineDir -ItemType Directory -Force | Out-Null
        $zipTargetPath = Join-Path $TargetDir $entry.fileName

        try {
            $tempPath = [System.IO.Path]::GetTempFileName()
            Remove-Item $tempPath -Force

            Download-FileWithProgress -Url $entry.sharePointUrl -Destination $tempPath -Name $($entry.fileName)

            if (-not (Test-Path $tempPath)) {
                Write-Log "ERROR: Download failed for $($entry.fileName)"
                exit 1
            }

            Move-Item -Force $tempPath $zipTargetPath
            Expand-Archive -LiteralPath $zipTargetPath -DestinationPath $engineDir -Force
            Remove-Item -Force $zipTargetPath
            Write-Log "Extracted Docker engine to: $engineDir"
        }
        catch {
            Write-Log "ERROR: $_"
            exit 1
        }
    }
    else {
        $targetPath = Join-Path $imageDir $entry.fileName
        if (Test-Path $targetPath) {
            Write-Log "Already present: $($entry.fileName)"
            continue
        }

        try {
            $tempPath = [System.IO.Path]::GetTempFileName()
            Remove-Item $tempPath -Force

            Download-FileWithProgress -Url $entry.sharePointUrl -Destination $tempPath -Name $($entry.fileName)

            if (-not (Test-Path $tempPath)) {
                Write-Log "ERROR: Download failed for $($entry.fileName)"
                exit 1
            }

            Move-Item -Force $tempPath $targetPath
            Write-Log "Saved: $targetPath"
        }
        catch {
            Write-Log "ERROR: $_"
            exit 1
        }
    }
}

Write-Log "All required files are present."
exit 0