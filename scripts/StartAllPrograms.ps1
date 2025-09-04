param([switch]$NoWait)

# Import common functions
. (Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Definition) "helpers\Common.ps1")

# Initialize paths and logging
$Paths = Get-ProjectPaths -ScriptName "startup"
Initialize-Logging -LogFile $Paths.LogFile

Write-Log "Start iRacing Automation programs..."

# Load configuration
$Config = Get-ProgramsConfig -ConfigPath $Paths.ConfigPath

foreach ($Program in $Config.programs) {
    Write-Log "Checking status: $($Program.name)"

    # Проверяем, запущена ли программа
    $ExecutableName = Get-ExecutableNameFromPaths -Paths $Program.paths
    $Process = Get-Process -Name $ExecutableName.Replace('.exe', '') -ErrorAction SilentlyContinue

    if ($Process) {
        Write-Log "$($Program.name) already started (PID: $($Process.Id))"
        continue
    }

    # Проверяем существование файла
    if (-not (Test-Path $Program.path)) {
        Write-Log "ERROR: File not found $($Program.path)"
        continue
    }

    try {
        Write-Log "Starting $($Program.name)..."
        # Start process detached from parent - this prevents CMD window dependency
        $ProcessStartInfo = New-Object System.Diagnostics.ProcessStartInfo
        $ProcessStartInfo.FileName = $Program.path
        $ProcessStartInfo.UseShellExecute = $true
        $ProcessStartInfo.CreateNoWindow = $false
        
        $DetachedProcess = [System.Diagnostics.Process]::Start($ProcessStartInfo)
        Write-Log "$($Program.name) started successfully (PID: $($DetachedProcess.Id))"

        if (-not $NoWait) {
            Start-Sleep -Seconds 2
        }
    }
    catch {
        Write-Log "ERROR starting $($Program.name): $($_.Exception.Message)"
    }
}

Write-Log "iRacing Automation programs start process finished."
