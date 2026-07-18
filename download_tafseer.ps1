# QIBRA AI - TAFSEER IBN KATHIR DOWNLOADER
# Downloads all 114 surahs Urdu tafseer

$ErrorActionPreference = "Continue"

$outputDir = "assets\data\tafseer\ibn_kathir_urdu"
$baseUrl = "https://cdn.jsdelivr.net/gh/spa5k/tafsir_api@main/tafsir/ur-tafseer-ibn-e-kaseer"

Write-Host "Creating directory..." -ForegroundColor Cyan
New-Item -ItemType Directory -Force -Path $outputDir | Out-Null

$totalSurahs = 114
$successCount = 0
$failCount = 0
$totalSize = 0

Write-Host ""
Write-Host "Downloading Tafseer Ibn Kathir (Urdu) - 114 surahs..." -ForegroundColor Yellow
Write-Host ""

for ($i = 1; $i -le $totalSurahs; $i++) {
    $url = "$baseUrl/$i.json"
    $outputFile = Join-Path $outputDir "$i.json"
    
    Write-Host "[$i/$totalSurahs] Surah $i..." -NoNewline
    
    try {
        Invoke-WebRequest -Uri $url -OutFile $outputFile -UseBasicParsing -ErrorAction Stop
        $fileSize = (Get-Item $outputFile).Length / 1KB
        $totalSize += $fileSize
        $fileSizeStr = "{0:N1}" -f $fileSize
        Write-Host " OK ($fileSizeStr KB)" -ForegroundColor Green
        $successCount++
    }
    catch {
        Write-Host " FAILED" -ForegroundColor Red
        $failCount++
    }
    
    # Small delay to avoid rate limiting
    if ($i % 10 -eq 0) {
        Start-Sleep -Milliseconds 500
    }
}

Write-Host ""
Write-Host "===========================================" -ForegroundColor Cyan
Write-Host "DOWNLOAD SUMMARY" -ForegroundColor Cyan
Write-Host "===========================================" -ForegroundColor Cyan
Write-Host "Successful: $successCount / $totalSurahs" -ForegroundColor Green
Write-Host "Failed:     $failCount / $totalSurahs" -ForegroundColor Red

$totalSizeMB = "{0:N2}" -f ($totalSize / 1024)
Write-Host "Total size: $totalSizeMB MB" -ForegroundColor Cyan
Write-Host "Files saved to: $outputDir" -ForegroundColor Yellow

Write-Host ""
Write-Host "Done!" -ForegroundColor Green