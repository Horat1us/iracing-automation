param(
    [Parameter(Mandatory=$true)]
    [string]$ProgramName
)

# Import common functions
. (Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Definition) "helpers\Common.ps1")

# Initialize paths and logging
$Paths = Get-ProjectPaths -ScriptName "restart"
Initialize-Logging -LogFile $Paths.LogFile

Write-Log "Restaring program: $ProgramName"

# Load configuration
$Config = Get-ProgramsConfig -ConfigPath $Paths.ConfigPath

$Program = $Config.programs | Where-Object { $_.name -eq $ProgramName }

if (-not $Program) {
    Write-Log "Error: Program $ProgramName not found in the configuration"
    exit 1
}

# Closing program
$ProcessName = $Program.executableName.Replace('.exe', '')
$Process = Get-Process -Name $ProcessName -ErrorAction SilentlyContinue

if ($Process) {
    Write-Log "Closing $ProgramName..."
    try {
        $Process.CloseMainWindow()
        Start-Sleep -Seconds 3

        if (-not $Process.HasExited) {
            $Process.Kill()
            Start-Sleep -Seconds 1
        }
        Write-Log "$ProgramName closed"
    }
    catch {
        Write-Log "ERROR while closing $ProgramName : $($_.Exception.Message)"
    }
}

# Starting program
Write-Log "Launching $ProgramName..."
try {
    Start-Process -FilePath $Program.path -ErrorAction Stop
    Write-Log "$ProgramName started successfuly"
}
catch {
    Write-Log "Error while starting $ProgramName : $($_.Exception.Message)"
}
