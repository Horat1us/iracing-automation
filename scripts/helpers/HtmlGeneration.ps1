# HTML Generation Helper Functions
# Contains functions for generating Stream Deck setup instructions HTML

function New-StreamDeckHtml {
    param(
        [array]$ButtonConfigs,
        [hashtable]$Paths,
        [hashtable]$GlobalIcons = @{}
    )
    
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
"@

    # Add StartAll button
    $StartAllIconHtml = if ($GlobalIcons.HasStartAllIcon) {
        "<img src=`"$($GlobalIcons.StartAllIconPath)`" alt=`"Start All Programs icon`">"
    } else {
        "<div class=`"no-icon`">▶</div>"
    }
    
    $StartAllIconPath = if ($GlobalIcons.HasStartAllIcon) {
        ($Paths.ProjectRoot + "\" + $GlobalIcons.StartAllIconPath) -replace '\\', '\\'
    } else {
        "Use emoji fallback (▶)"
    }
    
    $HtmlContent += @"
                <div class="button-card">
                    <h3>Start All Programs</h3>
                    <div class="button-info">
                        $StartAllIconHtml
                        <div>
                            <strong>Action:</strong> Start all configured programs<br>
                            <strong>File:</strong> <span class="file-path">$($Paths.ProjectRoot -replace '\\', '\\')\shell\StartAll.bat</span>
                            <br><strong>Icon:</strong> <span class="file-path">$StartAllIconPath</span>
                        </div>
                    </div>
                </div>
"@

    # Add StopAll button
    $StopAllIconHtml = if ($GlobalIcons.HasStopAllIcon) {
        "<img src=`"$($GlobalIcons.StopAllIconPath)`" alt=`"Stop All Programs icon`">"
    } else {
        "<div class=`"no-icon`">⏹</div>"
    }
    
    $StopAllIconPath = if ($GlobalIcons.HasStopAllIcon) {
        ($Paths.ProjectRoot + "\" + $GlobalIcons.StopAllIconPath) -replace '\\', '\\'
    } else {
        "Use emoji fallback (⏹)"
    }
    
    $HtmlContent += @"
                <div class="button-card">
                    <h3>Stop All Programs</h3>
                    <div class="button-info">
                        $StopAllIconHtml
                        <div>
                            <strong>Action:</strong> Stop all configured programs<br>
                            <strong>File:</strong> <span class="file-path">$($Paths.ProjectRoot -replace '\\', '\\')\shell\StopAll.bat</span>
                            <br><strong>Icon:</strong> <span class="file-path">$StopAllIconPath</span>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <h2>Individual Program Buttons</h2>
        <div class="button-grid">
"@

    # Add individual program buttons
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
            <li><strong>Start All</strong> - Launch all configured programs at once (play triangle overlay)</li>
            <li><strong>Stop All</strong> - Close all configured programs (stop square overlay)</li>
            <li><strong>Icon generation</strong> - Base icons are extracted from executables, then focus and restart variants are created with visual overlays</li>
            <li><strong>Overlay symbols</strong> - Eye (👁) for focus, circular arrow (🔄) for restart, play (▶) for start, stop (⏹) for stop</li>
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

    return $HtmlContent
}

function Save-StreamDeckHtml {
    param(
        [string]$HtmlContent,
        [string]$ProjectRoot
    )
    
    $HtmlPath = Join-Path $ProjectRoot "StreamDeckInstructions.html"
    $HtmlContent | Set-Content $HtmlPath -Encoding UTF8
    Write-Log "Generated: StreamDeckInstructions.html"
    
    return $HtmlPath
}