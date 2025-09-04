# iRacing Automation Installation Script
# Validates program paths, generates Stream Deck integration files

# Import helper modules
. (Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Definition) "helpers\Common.ps1")
. (Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Definition) "helpers\IconGeneration.ps1")
. (Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Definition) "helpers\HtmlGeneration.ps1")

# Initialize paths and logging
$Paths = Get-ProjectPaths -ScriptName "install"
Initialize-Logging -LogFile $Paths.LogFile

Write-Log "Starting iRacing Automation installation..."

# Check if programs.json already exists
if (Test-Path $Paths.ConfigPath) {
    $Response = Read-Host "Configuration file already exists. Overwrite? (y/N)"
    if ($Response -ne 'y' -and $Response -ne 'Y') {
        Write-Log "Installation cancelled by user"
        exit 0
    }
}

# Load initial configuration
$InitConfigPath = Join-Path $Paths.ProjectRoot "config\programs-init.json"
if (-not (Test-Path $InitConfigPath)) {
    Write-Log "ERROR: Initial configuration file not found: $InitConfigPath"
    exit 1
}

$InitConfig = Get-Content $InitConfigPath | ConvertFrom-Json
$ValidatedPrograms = @()

Write-Log "Validating program paths from initial configuration..."

# Validate each program in the configuration
foreach ($Program in $InitConfig.programs) {
    Write-Log "Checking $($Program.name)..."
    
    $FoundPath = $null
    $CurrentUsername = $env:USERNAME
    
    # Handle both single path (legacy) and multiple paths
    $PathsToCheck = if ($Program.paths) { $Program.paths } else { @($Program.path) }
    
    foreach ($TestPath in $PathsToCheck) {
        # Replace {USERNAME} placeholder with current username
        $ResolvedPath = $TestPath -replace '\{USERNAME\}', $CurrentUsername
        
        if (Test-Path $ResolvedPath) {
            $FoundPath = $ResolvedPath
            Write-Log "$($Program.name) found at $ResolvedPath"
            break
        }
    }
    
    if ($FoundPath) {
        # Create program object with single validated path
        $ValidatedProgram = @{
            name = $Program.name
            executableName = $Program.executableName
            path = $FoundPath
            windowTitle = $Program.windowTitle
        }
        $ValidatedPrograms += $ValidatedProgram
    }
    else {
        Write-Log "WARNING: $($Program.name) not found at any expected paths"
        Write-Host ""
        Write-Host "Program '$($Program.name)' not found at any expected paths:"
        foreach ($TestPath in $PathsToCheck) {
            $ResolvedPath = $TestPath -replace '\{USERNAME\}', $CurrentUsername
            Write-Host "  Tried: $ResolvedPath"
        }
        Write-Host ""
        
        do {
            $Choice = Read-Host "Choose action: (P)ath manual entry, (S)kip program, (Q)uit installation"
            $Choice = $Choice.ToUpper()
            
            switch ($Choice) {
                'P' {
                    do {
                        $NewPath = Read-Host "Enter correct path to $($Program.executableName)"
                        if (Test-Path $NewPath) {
                            $ValidatedProgram = @{
                                name = $Program.name
                                executableName = $Program.executableName
                                path = $NewPath
                                windowTitle = $Program.windowTitle
                            }
                            $ValidatedPrograms += $ValidatedProgram
                            Write-Log "$($Program.name) manually configured at $NewPath"
                            break
                        }
                        else {
                            Write-Host "ERROR: File not found at $NewPath"
                        }
                    } while ($true)
                    break
                }
                'S' {
                    Write-Log "$($Program.name) skipped by user"
                    break
                }
                'Q' {
                    Write-Log "Installation cancelled by user"
                    exit 0
                }
                default {
                    Write-Host "Invalid choice. Please enter P, S, or Q."
                }
            }
        } while ($Choice -notin @('P', 'S', 'Q'))
    }
}

# Ask user to add additional programs
Write-Host ""
Write-Host "Would you like to add additional programs? (y/N)"
$AddMore = Read-Host
if ($AddMore -eq 'y' -or $AddMore -eq 'Y') {
    do {
        Write-Host ""
        Write-Host "Adding new program..."
        
        $NewProgram = @{}
        $NewProgram.name = Read-Host "Enter program name"
        $NewProgram.executableName = Read-Host "Enter executable name (e.g., Program.exe)"
        
        do {
            $NewProgram.path = Read-Host "Enter full path to executable"
            if (Test-Path $NewProgram.path) {
                break
            }
            else {
                Write-Host "ERROR: File not found at $($NewProgram.path)"
            }
        } while ($true)
        
        $NewProgram.windowTitle = Read-Host "Enter window title (optional, press Enter to use program name)"
        if ([string]::IsNullOrWhiteSpace($NewProgram.windowTitle)) {
            $NewProgram.windowTitle = $NewProgram.name
        }
        
        $ValidatedPrograms += $NewProgram
        Write-Log "Added new program: $($NewProgram.name)"
        
        $Continue = Read-Host "Add another program? (y/N)"
    } while ($Continue -eq 'y' -or $Continue -eq 'Y')
}

# Create final configuration
$FinalConfig = @{
    programs = $ValidatedPrograms
}

# Save validated configuration
$FinalConfig | ConvertTo-Json -Depth 3 | Set-Content $Paths.ConfigPath

Write-Log "Generating bat files and icons for Stream Deck integration..."

# Create shell and icons directories if they don't exist
$ShellDir = Join-Path $Paths.ProjectRoot "shell"
$IconsDir = Join-Path $Paths.ProjectRoot "icons"
if (-not (Test-Path $ShellDir)) {
    New-Item -ItemType Directory -Path $ShellDir -Force | Out-Null
}
if (-not (Test-Path $IconsDir)) {
    New-Item -ItemType Directory -Path $IconsDir -Force | Out-Null
}

$ScriptsDir = Join-Path $Paths.ProjectRoot "scripts"

# Generate StartAll.bat
$StartAllContent = @"
@echo off
cd /d "$ScriptsDir"
powershell.exe -ExecutionPolicy Bypass -File "StartAllPrograms.ps1" -NoWait
"@
$StartAllPath = Join-Path $ShellDir "StartAll.bat"
$StartAllContent | Set-Content $StartAllPath
Write-Log "Generated: StartAll.bat"

# Generate StopAll.bat
$StopAllContent = @"
@echo off
cd /d "$ScriptsDir"
powershell.exe -ExecutionPolicy Bypass -File "StopAllPrograms.ps1"
"@
$StopAllPath = Join-Path $ShellDir "StopAll.bat"
$StopAllContent | Set-Content $StopAllPath
Write-Log "Generated: StopAll.bat"

# Extract icons and generate individual program bat files
$ButtonConfigs = @()
$IRacingIconPath = $null

foreach ($Program in $ValidatedPrograms) {
    $SafeProgramName = $Program.name -replace '[^a-zA-Z0-9]', '_'
    
    # Generate program icons using helper function
    $IconResults = New-ProgramIcons -Program $Program -IconsDir $IconsDir -SafeProgramName $SafeProgramName
    
    # Store iRacing icon path for global icons
    if ($Program.name -eq "iRacing" -and $IconResults.HasIcon) {
        $IRacingIconPath = Join-Path $IconsDir "$SafeProgramName.png"
    }
    
    # Generate Focus bat file
    $FocusContent = @"
@echo off
cd /d "$ScriptsDir"
powershell.exe -ExecutionPolicy Bypass -File "FocusWindow.ps1" -ProgramName "$($Program.name)"
"@
    $FocusPath = Join-Path $ShellDir "Focus_$SafeProgramName.bat"
    $FocusContent | Set-Content $FocusPath
    Write-Log "Generated: Focus_$SafeProgramName.bat"
    
    # Generate Restart bat file
    $RestartContent = @"
@echo off
cd /d "$ScriptsDir"
powershell.exe -ExecutionPolicy Bypass -File "RestartProgram.ps1" -ProgramName "$($Program.name)"
"@
    $RestartPath = Join-Path $ShellDir "Restart_$SafeProgramName.bat"
    $RestartContent | Set-Content $RestartPath
    Write-Log "Generated: Restart_$SafeProgramName.bat"
    
    # Store button configuration for HTML generation
    $ButtonConfigs += @{
        ProgramName = $Program.name
        SafeName = $SafeProgramName
        HasIcon = $IconResults.HasIcon
        BaseIconPath = $IconResults.BaseIconPath
        FocusIconPath = $IconResults.FocusIconPath
        RestartIconPath = $IconResults.RestartIconPath
        HasFocusIcon = $IconResults.HasFocusIcon
        HasRestartIcon = $IconResults.HasRestartIcon
        FocusBat = "shell\Focus_$SafeProgramName.bat"
        RestartBat = "shell\Restart_$SafeProgramName.bat"
    }
}

# Generate global action icons using iRacing icon
$GlobalIcons = @{}
if ($IRacingIconPath) {
    $GlobalIcons = New-GlobalActionIcons -BaseIconPath $IRacingIconPath -IconsDir $IconsDir
}

# Generate HTML instructions using helper function
$HtmlContent = New-StreamDeckHtml -ButtonConfigs $ButtonConfigs -Paths $Paths -GlobalIcons $GlobalIcons
$HtmlPath = Save-StreamDeckHtml -HtmlContent $HtmlContent -ProjectRoot $Paths.ProjectRoot

# Try to open HTML file in default browser
Write-Log "Attempting to open StreamDeckInstructions.html in browser..."
try {
    # Use Start-Process with -PassThru to capture the process and avoid blocking
    $BrowserProcess = Start-Process -FilePath $HtmlPath -PassThru -ErrorAction Stop
    Write-Log "Successfully opened StreamDeckInstructions.html in browser"
    Write-Host "StreamDeckInstructions.html opened in your default browser."
}
catch {
    Write-Log "WARNING: Could not open browser automatically: $($_.Exception.Message)"
    Write-Host "Could not open browser automatically. Please manually open: $HtmlPath"
}

Write-Log "Installation completed successfully!"
Write-Log "Configuration saved to: $($Paths.ConfigPath)"
Write-Log "Found and configured $($ValidatedPrograms.Count) programs"
Write-Log "Generated $((2 * $ValidatedPrograms.Count) + 2) bat files for Stream Deck"
Write-Log "Extracted $($ButtonConfigs.Count) program icons (72x72 PNG)"

Write-Host ""
Write-Host "Installation completed!"
Write-Host "- Generated bat files in shell/ directory"
Write-Host "- Extracted program icons to icons/ directory"
Write-Host "- Created StreamDeckInstructions.html with setup guide"
Write-Host "- Generated StartAll and StopAll icons with overlays"
Write-Host ""
Write-Host "Next steps:"
Write-Host "- Follow the setup instructions in the browser window that should have opened"
Write-Host "- If the browser didn't open automatically, manually open: StreamDeckInstructions.html"