param(
    [Parameter(Mandatory=$true)]
    [string]$ProgramName
)

# Import common functions
. (Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Definition) "helpers\Common.ps1")

# Initialize paths and logging
$Paths = Get-ProjectPaths -ScriptName "stop"
Initialize-Logging -LogFile $Paths.LogFile

Write-Log "Stopping program: $ProgramName"

# Load configuration
$Config = Get-ProgramsConfig -ConfigPath $Paths.ConfigPath

$Program = $Config.programs | Where-Object { $_.name -eq $ProgramName }

if (-not $Program) {
    Write-Log "ERROR: Program $ProgramName not found in configuration"
    exit 1
}

# Check if program is running
$ExecutableName = Get-ExecutableNameFromPaths -Paths $Program.paths
$ProcessName = $ExecutableName.Replace('.exe', '')
$Processes = Get-Process -Name $ProcessName -ErrorAction SilentlyContinue

if (-not $Processes) {
    Write-Log "$ProgramName is not currently running"
    exit 0
}

# Stop the program(s)
foreach ($Process in $Processes) {
    try {
        Write-Log "Stopping $ProgramName process (PID: $($Process.Id))..."
        
        # Try graceful close first
        $Process.CloseMainWindow()
        Start-Sleep -Seconds 3

        # Check if process has exited
        $Process.Refresh()
        if ($Process.HasExited) {
            Write-Log "$ProgramName stopped gracefully (PID: $($Process.Id))"
        } else {
            # Force kill if graceful close didn't work
            Write-Log "Force stopping $ProgramName (PID: $($Process.Id))"
            $Process.Kill()
            Start-Sleep -Seconds 1
            Write-Log "$ProgramName force stopped (PID: $($Process.Id))"
        }
    }
    catch {
        Write-Log "ERROR stopping $ProgramName (PID: $($Process.Id)): $($_.Exception.Message)"
        # Continue with other processes if multiple instances
    }
}

Write-Log "$ProgramName stop operation completed"