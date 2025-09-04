# Generate release notes from template and git commits
param(
    [Parameter(Mandatory=$true)]
    [string]$Version,
    [Parameter(Mandatory=$true)]
    [string]$OutputFile
)

Write-Host "Generating release notes for version: $Version"

# Get commits since last tag
try {
    $prevTag = git describe --tags --abbrev=0 HEAD~ 2>$null
    if ($LASTEXITCODE -eq 0 -and $prevTag) {
        Write-Host "Previous tag found: $prevTag"
        $commits = git log --pretty=format:"- %s (%h)" "$prevTag..HEAD"
    } else {
        Write-Host "No previous tag found, using all commits"
        $commits = git log --pretty=format:"- %s (%h)" HEAD
    }
} catch {
    Write-Host "Error getting git history, using placeholder"
    $commits = "- Initial release"
}

if (-not $commits) {
    $commits = "- No specific changes recorded"
}

Write-Host "Found commits:"
$commits | ForEach-Object { Write-Host "  $_" }

# Load template and replace placeholders
$template = Get-Content "release\release-notes.template.md" -Raw
$releaseNotes = $template.Replace("{VERSION}", $Version)
$releaseNotes = $releaseNotes.Replace("{COMMITS}", ($commits -join "`n"))

# Write release notes
$releaseNotes | Out-File -FilePath $OutputFile -Encoding UTF8

Write-Host "✅ Release notes generated: $OutputFile"