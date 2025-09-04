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
$ExecutableName = Get-ExecutableNameFromPath -Path $Program.path
$ProcessName = $ExecutableName.Replace('.exe', '')
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
    # Start process detached from parent - this prevents CMD window dependency
    $ProcessStartInfo = New-Object System.Diagnostics.ProcessStartInfo
    $ProcessStartInfo.FileName = $Program.path
    $ProcessStartInfo.UseShellExecute = $true
    $ProcessStartInfo.CreateNoWindow = $false
    
    $DetachedProcess = [System.Diagnostics.Process]::Start($ProcessStartInfo)
    Write-Log "$ProgramName started successfully (PID: $($DetachedProcess.Id))"
}
catch {
    Write-Log "Error while starting $ProgramName : $($_.Exception.Message)"
}
