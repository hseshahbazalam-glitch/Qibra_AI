# QIBRA AI - HADITH DATA DOWNLOADER
# Downloads all 6 books in Arabic + English + Urdu

$ErrorActionPreference = "Continue"

$baseUrl = "https://cdn.jsdelivr.net/gh/fawazahmed0/hadith-api@1/editions"
$outputDir = "assets\data\hadith"

Write-Host "Creating directories..." -ForegroundColor Cyan
New-Item -ItemType Directory -Force -Path $outputDir | Out-Null

$books = @(
    @{ slug = "bukhari"; folder = "bukhari"; name = "Sahih al-Bukhari" },
    @{ slug = "muslim"; folder = "muslim"; name = "Sahih Muslim" },
    @{ slug = "abudawud"; folder = "abudawud"; name = "Sunan Abu Dawud" },
    @{ slug = "tirmidhi"; folder = "tirmidhi"; name = "Jami at-Tirmidhi" },
    @{ slug = "nasai"; folder = "nasai"; name = "Sunan an-Nasai" },
    @{ slug = "ibnmajah"; folder = "ibnmajah"; name = "Sunan Ibn Majah" }
)

$languages = @(
    @{ prefix = "ara"; file = "arabic.json"; label = "Arabic" },
    @{ prefix = "eng"; file = "english.json"; label = "English" },
    @{ prefix = "urd"; file = "urdu.json"; label = "Urdu" }
)

$totalFiles = $books.Count * $languages.Count
$currentFile = 0
$successCount = 0
$failCount = 0

Write-Host ""
Write-Host "Starting download of $totalFiles files..." -ForegroundColor Yellow
Write-Host ""

foreach ($book in $books) {
    $bookFolder = Join-Path $outputDir $book.folder
    New-Item -ItemType Directory -Force -Path $bookFolder | Out-Null
    
    Write-Host "[BOOK] $($book.name)" -ForegroundColor Magenta
    
    foreach ($lang in $languages) {
        $currentFile++
        $url = "$baseUrl/$($lang.prefix)-$($book.slug).json"
        $outputFile = Join-Path $bookFolder $lang.file
        
        Write-Host "   [$currentFile/$totalFiles] $($lang.label)..." -NoNewline
        
        try {
            Invoke-WebRequest -Uri $url -OutFile $outputFile -UseBasicParsing -ErrorAction Stop
            $fileSize = (Get-Item $outputFile).Length / 1MB
            $fileSizeStr = "{0:N2}" -f $fileSize
            Write-Host " OK ($fileSizeStr MB)" -ForegroundColor Green
            $successCount++
        }
        catch {
            Write-Host " FAILED" -ForegroundColor Red
            Write-Host "      Error: $($_.Exception.Message)" -ForegroundColor Yellow
            $failCount++
        }
    }
    Write-Host ""
}

Write-Host "===========================================" -ForegroundColor Cyan
Write-Host "DOWNLOAD SUMMARY" -ForegroundColor Cyan
Write-Host "===========================================" -ForegroundColor Cyan
Write-Host "Successful: $successCount / $totalFiles" -ForegroundColor Green
Write-Host "Failed:     $failCount / $totalFiles" -ForegroundColor Red

if ($successCount -gt 0) {
    $totalSize = (Get-ChildItem -Path $outputDir -Recurse -File | Measure-Object -Property Length -Sum).Sum / 1MB
    $totalSizeStr = "{0:N2}" -f $totalSize
    Write-Host "Total size: $totalSizeStr MB" -ForegroundColor Cyan
    Write-Host "Files saved to: $outputDir" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Done!" -ForegroundColor Green