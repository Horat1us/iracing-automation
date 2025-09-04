function Get-ProjectPaths {
    param([string]$ScriptName = "common")
    
    $ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
    $ProjectRoot = Split-Path -Parent $ScriptDir
    
    return @{
        ScriptDir = $ScriptDir
        ProjectRoot = $ProjectRoot
        LogFile = Join-Path $ProjectRoot "logs\$($ScriptName)_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
        ConfigPath = Join-Path $ProjectRoot "config\programs.json"
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