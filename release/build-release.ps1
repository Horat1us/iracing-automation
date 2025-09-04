# Build script for creating release package
# This script is called by GitHub Actions
param(
    [Parameter(Mandatory=$true)]
    [string]$Version,
    [Parameter(Mandatory=$true)]
    [string]$ReleaseDir
)

Write-Host "Building release package for version: $Version"
Write-Host "Release directory: $ReleaseDir"

# Create release directory structure
New-Item -ItemType Directory -Path $ReleaseDir -Force
Write-Host "✅ Created release directory: $ReleaseDir"

# Copy essential directories
Copy-Item -Path "scripts" -Destination "$ReleaseDir\scripts" -Recurse
Copy-Item -Path "config" -Destination "$ReleaseDir\config" -Recurse
Write-Host "✅ Copied scripts and config directories"

# Copy release files
Copy-Item -Path "release\iRacing-Automation-Setup.bat" -Destination "$ReleaseDir\"
Copy-Item -Path "release\CHOOSE-YOUR-SETUP.txt" -Destination "$ReleaseDir\"
Copy-Item -Path "release\QUICKSTART.txt" -Destination "$ReleaseDir\"
Write-Host "✅ Copied release files"

# Create VERSION.txt from template
$versionContent = Get-Content "release\VERSION.template.txt" -Raw
$versionContent = $versionContent.Replace("{VERSION}", $Version)
$versionContent = $versionContent.Replace("{DATE}", (Get-Date -Format 'yyyy-MM-dd'))
$versionContent | Out-File -FilePath "$ReleaseDir\VERSION.txt" -Encoding UTF8
Write-Host "✅ Created VERSION.txt"

Write-Host "Release directory structure created successfully"

# Display package contents for verification
Write-Host "`n📦 Package contents:"
Get-ChildItem -Path $ReleaseDir -Recurse | ForEach-Object {
    $relativePath = $_.FullName.Replace((Resolve-Path $ReleaseDir).Path, '')
    Write-Host ("  " + $relativePath)
}