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
    $Process = Get-Process -Name $Program.executableName.Replace('.exe', '') -ErrorAction SilentlyContinue

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
        Start-Process -FilePath $Program.path -ErrorAction Stop
        Write-Log "$($Program.name) started successfuly"

        if (-not $NoWait) {
            Start-Sleep -Seconds 2
        }
    }
    catch {
        Write-Log "ERROR starting $($Program.name): $($_.Exception.Message)"
    }
}

Write-Log "iRacing Automation programs start process finished."
