# Batch File Generation Helper Functions
# Contains functions for generating Stream Deck batch files

function New-GlobalBatchFiles {
    param(
        [string]$ShellDir,
        [string]$ScriptsDir
    )
    
    $GeneratedCount = 0
    
    # Generate StartAll.bat
    $StartAllContent = @"
@echo off
cd /d "$ScriptsDir"
powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -Command "& { Start-Process powershell.exe -ArgumentList '-WindowStyle Hidden -ExecutionPolicy Bypass -File `"StartAllPrograms.ps1`"' -WindowStyle Hidden }"
"@
    $StartAllPath = Join-Path $ShellDir "StartAll.bat"
    $StartAllContent | Set-Content $StartAllPath
    Write-Log "Generated: StartAll.bat"
    $GeneratedCount++
    
    # Generate StopAll.bat
    $StopAllContent = @"
@echo off
cd /d "$ScriptsDir"
powershell.exe -ExecutionPolicy Bypass -File "StopAllPrograms.ps1"
"@
    $StopAllPath = Join-Path $ShellDir "StopAll.bat"
    $StopAllContent | Set-Content $StopAllPath
    Write-Log "Generated: StopAll.bat"
    $GeneratedCount++
    
    return $GeneratedCount
}

function New-ProgramBatchFiles {
    param(
        [PSCustomObject]$Program,
        [string]$ShellDir,
        [string]$ScriptsDir,
        [string]$SafeProgramName
    )
    
    $GeneratedCount = 0
    
    # Generate Focus bat file
    $FocusContent = @"
@echo off
cd /d "$ScriptsDir"
powershell.exe -ExecutionPolicy Bypass -File "FocusWindow.ps1" -ProgramName "$($Program.name)"
"@
    $FocusPath = Join-Path $ShellDir "Focus_$SafeProgramName.bat"
    $FocusContent | Set-Content $FocusPath
    Write-Log "Generated: Focus_$SafeProgramName.bat"
    $GeneratedCount++
    
    # Generate Restart bat file
    $RestartContent = @"
@echo off
cd /d "$ScriptsDir"
powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -Command "& { Start-Process powershell.exe -ArgumentList '-WindowStyle Hidden -ExecutionPolicy Bypass -File `"RestartProgram.ps1`" -ProgramName `"$($Program.name)`"' -WindowStyle Hidden }"
"@
    $RestartPath = Join-Path $ShellDir "Restart_$SafeProgramName.bat"
    $RestartContent | Set-Content $RestartPath
    Write-Log "Generated: Restart_$SafeProgramName.bat"
    $GeneratedCount++
    
    # Generate Start bat file
    $StartContent = @"
@echo off
cd /d "$ScriptsDir"
powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -Command "& { Start-Process powershell.exe -ArgumentList '-WindowStyle Hidden -ExecutionPolicy Bypass -File `"StartProgram.ps1`" -ProgramName `"$($Program.name)`"' -WindowStyle Hidden }"
"@
    $StartPath = Join-Path $ShellDir "Start_$SafeProgramName.bat"
    $StartContent | Set-Content $StartPath
    Write-Log "Generated: Start_$SafeProgramName.bat"
    $GeneratedCount++
    
    # Generate Stop bat file
    $StopContent = @"
@echo off
cd /d "$ScriptsDir"
powershell.exe -ExecutionPolicy Bypass -File "StopProgram.ps1" -ProgramName "$($Program.name)"
"@
    $StopPath = Join-Path $ShellDir "Stop_$SafeProgramName.bat"
    $StopContent | Set-Content $StopPath
    Write-Log "Generated: Stop_$SafeProgramName.bat"
    $GeneratedCount++
    
    return $GeneratedCount
}