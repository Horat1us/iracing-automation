param(
    [Parameter(Mandatory=$true)]
    [string]$ProgramName
)

# Import common functions
. (Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Definition) "helpers\Common.ps1")

# Initialize paths and logging
$Paths = Get-ProjectPaths -ScriptName "focus"
Initialize-Logging -LogFile $Paths.LogFile

Write-Log "Focusing window for program: $ProgramName"

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
$Process = Get-Process -Name $ProcessName -ErrorAction SilentlyContinue

if (-not $Process) {
    Write-Log "ERROR: Program $ProgramName is not running"
    exit 1
}

# Find windows by title (with partial matching support)
$PartialMatch = if ($Program.partialMatch) { $Program.partialMatch } else { $false }
$Windows = Find-WindowByTitle -WindowTitle $Program.windowTitle -PartialMatch $PartialMatch -ProcessName $ProcessName

if ($Windows -and $Windows.Count -gt 0) {
    # Focus the first matching window
    $hWnd = $Windows[0]
    
    Write-Log "Found window with title matching '$($Program.windowTitle)' (partial: $PartialMatch)"
    
    if ([WindowAPI]::IsIconic($hWnd)) {
        [WindowAPI]::ShowWindow($hWnd, 9) # SW_RESTORE
        Write-Log "Restored minimized window"
    }

    [WindowAPI]::SetForegroundWindow($hWnd)
    Write-Log "Window $ProgramName activated successfully"
    exit 0
} else {
    # Fallback to process main window handle
    Write-Log "Window title matching failed, falling back to process main window"
    
    foreach ($Proc in $Process) {
        $hWnd = $Proc.MainWindowHandle

        if ($hWnd -ne [IntPtr]::Zero) {
            if ([WindowAPI]::IsIconic($hWnd)) {
                [WindowAPI]::ShowWindow($hWnd, 9) # SW_RESTORE
            }

            [WindowAPI]::SetForegroundWindow($hWnd)
            Write-Log "Window $ProgramName activated using fallback method"
            exit 0
        }
    }
}

Write-Log "ERROR: Unable to find or focus window for program $ProgramName"
exit 1