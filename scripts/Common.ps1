function Get-ProjectPaths {
    param([string]$ScriptName = "common")
    
    # Get the directory of the calling script
    $CallerScript = Get-PSCallStack | Select-Object -Skip 1 -First 1
    if ($CallerScript.ScriptName) {
        $ScriptDir = Split-Path -Parent $CallerScript.ScriptName
    } else {
        $ScriptDir = $PSScriptRoot
    }
    $ProjectRoot = Split-Path -Parent $ScriptDir
    
    # Build log file name safely
    $LogFileName = $ScriptName + "_" + (Get-Date -Format 'yyyyMMdd_HHmmss') + ".log"
    $LogsDir = Join-Path $ProjectRoot "logs"
    $ConfigDir = Join-Path $ProjectRoot "config"
    
    return @{
        ScriptDir = $ScriptDir
        ProjectRoot = $ProjectRoot
        LogFile = Join-Path $LogsDir $LogFileName
        ConfigPath = Join-Path $ConfigDir "programs.json"
    }
}

function Initialize-Logging {
    param([string]$LogFile)
    
    $global:CurrentLogFile = $LogFile
    
    function global:Write-Log {
        param([string]$Message)
        $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        "$Timestamp - $Message" | Out-File -FilePath $global:CurrentLogFile -Append
        Write-Host $Message
    }
}

function Get-ProgramsConfig {
    param([string]$ConfigPath)
    
    if (-not (Test-Path $ConfigPath)) {
        throw "Configuration file not found: $ConfigPath"
    }
    
    return Get-Content $ConfigPath | ConvertFrom-Json
}