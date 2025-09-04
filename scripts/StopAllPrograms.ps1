# Import common functions
. (Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Definition) "Common.ps1")

# Initialize paths and logging
$Paths = Get-ProjectPaths -ScriptName "stop"
Initialize-Logging -LogFile $Paths.LogFile

Write-Log "Stopping iRacing Automation programs..."

# Load configuration
$Config = Get-ProgramsConfig -ConfigPath $Paths.ConfigPath

foreach ($Program in $Config.programs) {
    Write-Log "Stopping: $($Program.name)"

    $ProcessName = $Program.executableName.Replace('.exe', '')
    $Processes = Get-Process -Name $ProcessName -ErrorAction SilentlyContinue

    if ($Processes) {
        foreach ($Process in $Processes) {
            try {
                Write-Log "Stopping process $($Program.name) (PID: $($Process.Id))"
                $Process.CloseMainWindow()
                Start-Sleep -Seconds 3

                if (-not $Process.HasExited) {
                    Write-Log "Force stop $($Program.name)"
                    $Process.Kill()
                }

                Write-Log "$($Program.name) stopped successfuly"
            }
            catch {
                Write-Log "ERROR stopping $($Program.name): $($_.Exception.Message)"
            }
        }
    }
    else {
        Write-Log "$($Program.name) not running"
    }
}

Write-Log "iRacing Automation programs start process finished."