param(
    [Parameter(Mandatory=$true)]
    [string]$ProgramName
)

# Import common functions
. (Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Definition) "helpers\Common.ps1")

# Initialize paths and logging
$Paths = Get-ProjectPaths -ScriptName "start"
Initialize-Logging -LogFile $Paths.LogFile

Write-Log "Starting program: $ProgramName"

# Load configuration
$Config = Get-ProgramsConfig -ConfigPath $Paths.ConfigPath

$Program = $Config.programs | Where-Object { $_.name -eq $ProgramName }

if (-not $Program) {
    Write-Log "ERROR: Program $ProgramName not found in configuration"
    exit 1
}

# Check if program is already running
$ExecutableName = Get-ExecutableNameFromPaths -Paths $Program.paths
$ProcessName = $ExecutableName.Replace('.exe', '')
$Process = Get-Process -Name $ProcessName -ErrorAction SilentlyContinue

if ($Process) {
    Write-Log "$ProgramName is already running (PID: $($Process.Id))"
    exit 0
}

# Check if executable file exists
if (-not (Test-Path $Program.path)) {
    Write-Log "ERROR: Executable not found at $($Program.path)"
    exit 1
}

# Start the program
try {
    Write-Log "Starting $ProgramName..."
    # Start process detached from parent - this prevents CMD window dependency
    $ProcessStartInfo = New-Object System.Diagnostics.ProcessStartInfo
    $ProcessStartInfo.FileName = $Program.path
    $ProcessStartInfo.UseShellExecute = $true
    $ProcessStartInfo.CreateNoWindow = $false
    
    $DetachedProcess = [System.Diagnostics.Process]::Start($ProcessStartInfo)
    Write-Log "$ProgramName started successfully (PID: $($DetachedProcess.Id))"
}
catch {
    Write-Log "ERROR starting program: $($_.Exception.Message)"
    exit 1
}

Write-Log "$ProgramName start operation completed successfully"