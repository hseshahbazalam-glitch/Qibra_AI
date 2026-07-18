# QIBRA AI - QURAN URDU TRANSLATIONS DOWNLOADER
# Downloads top 5 Urdu translations + Roman Urdu

$ErrorActionPreference = "Continue"

$outputDir = "assets\data\quran"
$baseUrl = "https://cdn.jsdelivr.net/gh/fawazahmed0/quran-api@1/editions"

Write-Host "Creating directories..." -ForegroundColor Cyan
New-Item -ItemType Directory -Force -Path $outputDir | Out-Null

# Best Urdu translations (verified working URLs)
$translations = @(
    @{ 
        code = "urd-fatehmuhammadja"
        file = "translation_ur_jalandhry.json"
        name = "Fateh Muhammad Jalandhry (Most Popular)"
    },
    @{ 
        code = "urd-muhammadjunagar"
        file = "translation_ur_junagarhi.json"
        name = "Muhammad Junagarhi (Authentic)"
    },
    @{ 
        code = "urd-muhammadtaqiusm"
        file = "translation_ur_usmani.json"
        name = "Muhammad Taqi Usmani (Modern Scholar)"
    },
    @{ 
        code = "urd-muhammadtahirul"
        file = "translation_ur_tahirulqadri.json"
        name = "Muhammad Tahir-ul-Qadri (Detailed)"
    },
    @{ 
        code = "urd-abulaalamaududi-la"
        file = "translation_ur_maududi_roman.json"
        name = "Abul A'la Maududi - Roman Urdu (Latin)"
    }
)

$total = $translations.Count
$current = 0
$successCount = 0
$failCount = 0

Write-Host ""
Write-Host "Starting download of $total Urdu translations..." -ForegroundColor Yellow
Write-Host ""

foreach ($trans in $translations) {
    $current++
    $url = "$baseUrl/$($trans.code).json"
    $outputFile = Join-Path $outputDir $trans.file
    
    Write-Host "[$current/$total] $($trans.name)" -ForegroundColor Magenta
    
    try {
        Invoke-WebRequest -Uri $url -OutFile $outputFile -UseBasicParsing -ErrorAction Stop
        $fileSize = (Get-Item $outputFile).Length / 1MB
        $fileSizeStr = "{0:N2}" -f $fileSize
        Write-Host "   OK ($fileSizeStr MB)" -ForegroundColor Green
        $successCount++
    }
    catch {
        Write-Host "   FAILED" -ForegroundColor Red
        Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Yellow
        $failCount++
    }
    Write-Host ""
}

Write-Host "===========================================" -ForegroundColor Cyan
Write-Host "DOWNLOAD SUMMARY" -ForegroundColor Cyan
Write-Host "===========================================" -ForegroundColor Cyan
Write-Host "Successful: $successCount / $total" -ForegroundColor Green
Write-Host "Failed:     $failCount / $total" -ForegroundColor Red

if ($successCount -gt 0) {
    $totalSize = (Get-ChildItem -Path $outputDir -Recurse -File | Measure-Object -Property Length -Sum).Sum / 1MB
    $totalSizeStr = "{0:N2}" -f $totalSize
    Write-Host "Total Quran folder size: $totalSizeStr MB" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "Files in assets/data/quran/:" -ForegroundColor Cyan
Get-ChildItem -Path $outputDir -File | ForEach-Object {
    $size = "{0:N2}" -f ($_.Length / 1MB)
    Write-Host "   $($_.Name) ($size MB)" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Done!" -ForegroundColor Green