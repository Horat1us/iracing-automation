# Import common functions
. (Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Definition) "Common.ps1")

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

# Add icon extraction function
Add-Type -AssemblyName System.Drawing

function Extract-Icon {
    param(
        [string]$ExecutablePath,
        [string]$OutputPath
    )
    
    try {
        $Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($ExecutablePath)
        if ($Icon) {
            $Bitmap = $Icon.ToBitmap()
            $ResizedBitmap = New-Object System.Drawing.Bitmap($Bitmap, 72, 72)
            $ResizedBitmap.Save($OutputPath, [System.Drawing.Imaging.ImageFormat]::Png)
            $ResizedBitmap.Dispose()
            $Bitmap.Dispose()
            $Icon.Dispose()
            return $true
        }
    }
    catch {
        Write-Log "WARNING: Could not extract icon from $ExecutablePath : $($_.Exception.Message)"
    }
    return $false
}

function Add-IconOverlay {
    param(
        [string]$BaseIconPath,
        [string]$OutputPath,
        [string]$OverlayType  # "focus" or "restart"
    )
    
    try {
        if (-not (Test-Path $BaseIconPath)) {
            return $false
        }
        
        # Load the base icon
        $BaseImage = [System.Drawing.Image]::FromFile($BaseIconPath)
        $Canvas = New-Object System.Drawing.Bitmap($BaseImage.Width, $BaseImage.Height)
        $Graphics = [System.Drawing.Graphics]::FromImage($Canvas)
        
        # Draw the base image
        $Graphics.DrawImage($BaseImage, 0, 0)
        
        # Set up overlay properties
        $OverlaySize = [int]($BaseImage.Width * 0.4)  # 40% of icon size
        $OverlayX = $BaseImage.Width - $OverlaySize - 2
        $OverlayY = $BaseImage.Height - $OverlaySize - 2
        
        # Create overlay background circle
        $OverlayBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(200, 255, 255, 255))
        $Graphics.FillEllipse($OverlayBrush, $OverlayX, $OverlayY, $OverlaySize, $OverlaySize)
        
        # Draw overlay border
        $BorderPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(150, 0, 0, 0), 1)
        $Graphics.DrawEllipse($BorderPen, $OverlayX, $OverlayY, $OverlaySize, $OverlaySize)
        
        # Draw overlay symbol
        $SymbolPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(200, 0, 0, 0), 2)
        $SymbolBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(200, 0, 0, 0))
        
        $CenterX = $OverlayX + ($OverlaySize / 2)
        $CenterY = $OverlayY + ($OverlaySize / 2)
        $SymbolRadius = [int]($OverlaySize * 0.25)
        
        if ($OverlayType -eq "focus") {
            # Draw eye symbol for focus
            $EyeWidth = [int]($OverlaySize * 0.6)
            $EyeHeight = [int]($OverlaySize * 0.35)
            $EyeRect = New-Object System.Drawing.Rectangle(($CenterX - $EyeWidth/2), ($CenterY - $EyeHeight/2), $EyeWidth, $EyeHeight)
            $Graphics.DrawEllipse($SymbolPen, $EyeRect)
            
            # Draw pupil
            $PupilSize = [int]($OverlaySize * 0.15)
            $Graphics.FillEllipse($SymbolBrush, ($CenterX - $PupilSize/2), ($CenterY - $PupilSize/2), $PupilSize, $PupilSize)
        }
        elseif ($OverlayType -eq "restart") {
            # Draw circular arrow for restart
            $ArrowRadius = [int]($OverlaySize * 0.25)
            $ArrowRect = New-Object System.Drawing.Rectangle(($CenterX - $ArrowRadius), ($CenterY - $ArrowRadius), ($ArrowRadius * 2), ($ArrowRadius * 2))
            
            # Draw circular arrow (partial circle with arrow head)
            $Graphics.DrawArc($SymbolPen, $ArrowRect, -45, 270)
            
            # Draw arrow head
            $ArrowHeadSize = 4
            $ArrowPoints = @(
                (New-Object System.Drawing.Point(($CenterX + $ArrowRadius - 2), ($CenterY - $ArrowRadius + 4))),
                (New-Object System.Drawing.Point(($CenterX + $ArrowRadius + 2), ($CenterY - $ArrowRadius - 2))),
                (New-Object System.Drawing.Point(($CenterX + $ArrowRadius - 6), ($CenterY - $ArrowRadius - 2)))
            )
            $Graphics.FillPolygon($SymbolBrush, $ArrowPoints)
        }
        
        # Save the result
        $Canvas.Save($OutputPath, [System.Drawing.Imaging.ImageFormat]::Png)
        
        # Cleanup
        $Graphics.Dispose()
        $Canvas.Dispose()
        $BaseImage.Dispose()
        $OverlayBrush.Dispose()
        $BorderPen.Dispose()
        $SymbolPen.Dispose()
        $SymbolBrush.Dispose()
        
        return $true
    }
    catch {
        Write-Log "WARNING: Could not create overlay icon: $($_.Exception.Message)"
        return $false
    }
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

foreach ($Program in $ValidatedPrograms) {
    $SafeProgramName = $Program.name -replace '[^a-zA-Z0-9]', '_'
    
    # Extract base icon from executable
    $BaseIconPath = Join-Path $IconsDir "$SafeProgramName.png"
    $IconExtracted = Extract-Icon -ExecutablePath $Program.path -OutputPath $BaseIconPath
    
    # Generate overlay icons if base icon was extracted
    $FocusIconPath = $null
    $RestartIconPath = $null
    $HasFocusIcon = $false
    $HasRestartIcon = $false
    
    if ($IconExtracted) {
        Write-Log "Extracted base icon for $($Program.name)"
        
        # Create focus icon with eye overlay
        $FocusIconPath = Join-Path $IconsDir "$SafeProgramName" + "_focus.png"
        $HasFocusIcon = Add-IconOverlay -BaseIconPath $BaseIconPath -OutputPath $FocusIconPath -OverlayType "focus"
        if ($HasFocusIcon) {
            Write-Log "Created focus icon for $($Program.name)"
        }
        
        # Create restart icon with circular arrow overlay
        $RestartIconPath = Join-Path $IconsDir "$SafeProgramName" + "_restart.png"
        $HasRestartIcon = Add-IconOverlay -BaseIconPath $BaseIconPath -OutputPath $RestartIconPath -OverlayType "restart"
        if ($HasRestartIcon) {
            Write-Log "Created restart icon for $($Program.name)"
        }
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
        HasIcon = $IconExtracted
        BaseIconPath = if ($IconExtracted) { "icons\$SafeProgramName.png" } else { $null }
        FocusIconPath = if ($HasFocusIcon) { "icons\$SafeProgramName" + "_focus.png" } else { $null }
        RestartIconPath = if ($HasRestartIcon) { "icons\$SafeProgramName" + "_restart.png" } else { $null }
        HasFocusIcon = $HasFocusIcon
        HasRestartIcon = $HasRestartIcon
        FocusBat = "shell\Focus_$SafeProgramName.bat"
        RestartBat = "shell\Restart_$SafeProgramName.bat"
    }
}

# Generate HTML instructions for Stream Deck configuration
Write-Log "Generating Stream Deck configuration instructions..."

$HtmlContent = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>iRacing Automation - Stream Deck Setup</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background-color: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        h1 { color: #2c3e50; border-bottom: 2px solid #3498db; padding-bottom: 10px; }
        h2 { color: #34495e; margin-top: 30px; }
        .button-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 20px; margin: 20px 0; }
        .button-card { border: 1px solid #ddd; border-radius: 8px; padding: 15px; background: #fafafa; }
        .button-card h3 { margin: 0 0 10px 0; color: #2c3e50; }
        .button-info { display: flex; align-items: center; margin: 10px 0; }
        .button-info img { width: 32px; height: 32px; margin-right: 10px; border-radius: 4px; }
        .button-info .no-icon { width: 32px; height: 32px; margin-right: 10px; background: #bdc3c7; border-radius: 4px; display: flex; align-items: center; justify-content: center; color: white; font-size: 12px; }
        .file-path { font-family: monospace; background: #ecf0f1; padding: 2px 6px; border-radius: 3px; font-size: 12px; }
        .global-buttons { background: #e8f6f3; padding: 15px; border-radius: 8px; margin: 20px 0; }
        .instructions { background: #fff3cd; padding: 15px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #ffc107; }
    </style>
</head>
<body>
    <div class="container">
        <h1>iRacing Automation - Stream Deck Configuration</h1>
        
        <div class="instructions">
            <h3>Setup Instructions:</h3>
            <ol>
                <li>Open Stream Deck software</li>
                <li>Create a new profile or select an existing one</li>
                <li>Drag "System: Open" action to each button</li>
                <li>Configure each button with the corresponding bat file path and icon shown below</li>
                <li>Test each button to ensure it works correctly</li>
            </ol>
        </div>

        <div class="global-buttons">
            <h2>Global Control Buttons</h2>
            <div class="button-grid">
                <div class="button-card">
                    <h3>Start All Programs</h3>
                    <div class="button-info">
                        <div class="no-icon">▶</div>
                        <div>
                            <strong>Action:</strong> Start all configured programs<br>
                            <strong>File:</strong> <span class="file-path">$($Paths.ProjectRoot -replace '\\', '\\')\shell\StartAll.bat</span>
                        </div>
                    </div>
                </div>
                <div class="button-card">
                    <h3>Stop All Programs</h3>
                    <div class="button-info">
                        <div class="no-icon">⏹</div>
                        <div>
                            <strong>Action:</strong> Stop all configured programs<br>
                            <strong>File:</strong> <span class="file-path">$($Paths.ProjectRoot -replace '\\', '\\')\shell\StopAll.bat</span>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <h2>Individual Program Buttons</h2>
        <div class="button-grid">
"@

foreach ($ButtonConfig in $ButtonConfigs) {
    # Generate appropriate icons for each button type
    $FocusIconHtml = if ($ButtonConfig.HasFocusIcon) {
        "<img src=`"$($ButtonConfig.FocusIconPath)`" alt=`"$($ButtonConfig.ProgramName) focus icon`">"
    } elseif ($ButtonConfig.HasIcon) {
        "<img src=`"$($ButtonConfig.BaseIconPath)`" alt=`"$($ButtonConfig.ProgramName) icon`">"
    } else {
        "<div class=`"no-icon`">👁</div>"
    }
    
    $RestartIconHtml = if ($ButtonConfig.HasRestartIcon) {
        "<img src=`"$($ButtonConfig.RestartIconPath)`" alt=`"$($ButtonConfig.ProgramName) restart icon`">"
    } elseif ($ButtonConfig.HasIcon) {
        "<img src=`"$($ButtonConfig.BaseIconPath)`" alt=`"$($ButtonConfig.ProgramName) icon`">"
    } else {
        "<div class=`"no-icon`">🔄</div>"
    }
    
    $FocusBatPath = ($Paths.ProjectRoot + "\" + $ButtonConfig.FocusBat) -replace '\\', '\\'
    $RestartBatPath = ($Paths.ProjectRoot + "\" + $ButtonConfig.RestartBat) -replace '\\', '\\'
    
    # Determine icon paths to display
    $FocusIconDisplayPath = if ($ButtonConfig.HasFocusIcon) {
        ($Paths.ProjectRoot + "\" + $ButtonConfig.FocusIconPath) -replace '\\', '\\'
    } elseif ($ButtonConfig.HasIcon) {
        ($Paths.ProjectRoot + "\" + $ButtonConfig.BaseIconPath) -replace '\\', '\\'
    } else {
        "Use emoji fallback (👁)"
    }
    
    $RestartIconDisplayPath = if ($ButtonConfig.HasRestartIcon) {
        ($Paths.ProjectRoot + "\" + $ButtonConfig.RestartIconPath) -replace '\\', '\\'
    } elseif ($ButtonConfig.HasIcon) {
        ($Paths.ProjectRoot + "\" + $ButtonConfig.BaseIconPath) -replace '\\', '\\'
    } else {
        "Use emoji fallback (🔄)"
    }
    
    $HtmlContent += @"
            <div class="button-card">
                <h3>$($ButtonConfig.ProgramName)</h3>
                
                <div class="button-info">
                    $FocusIconHtml
                    <div>
                        <strong>Focus Button</strong><br>
                        <strong>File:</strong> <span class="file-path">$FocusBatPath</span>
                        <br><strong>Icon:</strong> <span class="file-path">$FocusIconDisplayPath</span>
                    </div>
                </div>
                
                <div class="button-info">
                    $RestartIconHtml
                    <div>
                        <strong>Restart Button</strong><br>
                        <strong>File:</strong> <span class="file-path">$RestartBatPath</span>
                        <br><strong>Icon:</strong> <span class="file-path">$RestartIconDisplayPath</span>
                    </div>
                </div>
            </div>
"@
}

$HtmlContent += @"
        </div>

        <h2>Button Configuration Tips</h2>
        <ul>
            <li><strong>Focus buttons</strong> - Bring the program window to the foreground (eye overlay icon)</li>
            <li><strong>Restart buttons</strong> - Close and restart the specific program (circular arrow overlay icon)</li>
            <li><strong>Start All</strong> - Launch all configured programs at once</li>
            <li><strong>Stop All</strong> - Close all configured programs</li>
            <li><strong>Icon generation</strong> - Base icons are extracted from executables, then focus and restart variants are created with visual overlays</li>
            <li><strong>Overlay symbols</strong> - Eye symbol (👁) for focus actions, circular arrow (🔄) for restart actions</li>
            <li>All bat files use absolute paths and will work regardless of current directory</li>
        </ul>

        <div class="instructions">
            <h3>Troubleshooting:</h3>
            <ul>
                <li>If buttons don't work, ensure PowerShell execution policy allows script execution</li>
                <li>Run <code>Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser</code> in PowerShell as administrator if needed</li>
                <li>Check log files in the <code>logs/</code> directory for detailed error information</li>
            </ul>
        </div>

        <footer style="margin-top: 40px; padding-top: 20px; border-top: 1px solid #ddd; color: #7f8c8d; text-align: center;">
            <p>Generated automatically by iRacing Automation Install.ps1 script</p>
        </footer>
    </div>
</body>
</html>
"@

$HtmlPath = Join-Path $Paths.ProjectRoot "StreamDeckInstructions.html"
$HtmlContent | Set-Content $HtmlPath -Encoding UTF8
Write-Log "Generated: StreamDeckInstructions.html"

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
Write-Host ""
Write-Host "Next steps:"
Write-Host "- Follow the setup instructions in the browser window that should have opened"
Write-Host "- If the browser didn't open automatically, manually open: StreamDeckInstructions.html"