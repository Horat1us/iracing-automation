function Get-ProjectPaths {
    param([string]$ScriptName = "common")
    
    $CallerScript = Get-PSCallStack | Select-Object -Skip 1 -First 1
    $ScriptDir = Split-Path -Parent $CallerScript.ScriptName
    $ProjectRoot = Split-Path -Parent $ScriptDir
    
    $LogFileName = "$ScriptName" + "_" + (Get-Date -Format 'yyyyMMdd_HHmmss') + ".log"
    
    return @{
        ScriptDir = $ScriptDir
        ProjectRoot = $ProjectRoot
        LogFile = Join-Path $ProjectRoot (Join-Path "logs" $LogFileName)
        ConfigPath = Join-Path $ProjectRoot (Join-Path "config" "programs.json")
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