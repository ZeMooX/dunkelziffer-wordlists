param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$scrapeDir,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$outDir
)

$scrapeDir = $scrapeDir | Resolve-Path
$cleanRoot = $scrapeDir.Substring(0, $scrapeDir.Length - 1)
$pathRegex = [regex] "((\/[\w\.\-\(\)\[\]]+)+\/)+[\w\.\-\(\)\[\]]+"

$dirOutFile = Join-Path $outDir "directories.txt"
$fileOutFile = Join-Path $outDir "files.txt"
$combinedOutFile = Join-Path $outDir "combined.txt"

Write-Host "[+] " -ForegroundColor Magenta -NoNewline; Write-Host "Scraping directory paths.."
Get-ChildItem $scrapeDir -Recurse -Directory | 
Select-Object FullName | 
ForEach-Object { $_.FullName.Replace($cleanRoot, "") } | 
Set-Content $dirOutFile

Write-Host "[+] " -ForegroundColor Magenta -NoNewline; Write-Host "Scraping file paths.."
$files = Get-ChildItem $scrapeDir -Recurse -File
$files | 
Select-Object FullName | 
ForEach-Object { $_.FullName.Replace($cleanRoot , "") } | 
Set-Content $fileOutFile

Write-Host "[+] " -ForegroundColor Magenta -NoNewline; Write-Host "Scraping everything.."
Get-ChildItem $scrapeDir -Recurse | 
Select-Object FullName | 
ForEach-Object { $_.FullName.Replace($cleanRoot, "") } | 
Set-Content $combinedOutFile

Write-Host "[+] " -ForegroundColor Magenta -NoNewline; Write-Host "Extracting paths from files.."
foreach ($file in $files) {
    $content = Get-Content $file.FullName
    foreach ($line in $content) {
        foreach ($match in $pathRegex.Matches($line)) {
            if ($match.Value -match "\.[a-zA-Z0-9]+$") {
                Add-Content $fileOutFile $match.Value
                Add-Content $combinedOutFile $match.Value
            }
            elseif ($match.Value -match "\\[^\\]+\\?$") {
                Add-Content $dirOutFile $match.Value
                Add-Content $combinedOutFile $match.Value
            }
        }
    }
}

Write-Host "[+] " -ForegroundColor Magenta -NoNewline; Write-Host "Deduplicating and normalizing wordlists, this may take a while.."
(Get-Content $dirOutFile).replace('\', '/') | Select-Object -Unique | Sort-Object | Set-Content $dirOutFile
(Get-Content $fileOutFile).replace('\', '/') | Select-Object -Unique | Sort-Object | Set-Content $fileOutFile
(Get-Content $combinedOutFile).replace('\', '/') | Select-Object -Unique | Sort-Object | Set-Content $combinedOutFile

Write-Host "[+] " -ForegroundColor Green -NoNewline; Write-Host "Done!"