# PowerShell script that gets compiled to EXE
# This script handles PowerShell detection and installation for the EXE entry point
param()

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

function Show-MessageBox {
    param([string]$Message, [string]$Title, [string]$Type = "Information")
    
    $ButtonType = switch($Type) {
        "Question" { [System.Windows.Forms.MessageBoxButtons]::YesNo }
        "Error" { [System.Windows.Forms.MessageBoxButtons]::OK }
        default { [System.Windows.Forms.MessageBoxButtons]::OK }
    }
    
    $IconType = switch($Type) {
        "Question" { [System.Windows.Forms.MessageBoxIcon]::Question }
        "Error" { [System.Windows.Forms.MessageBoxIcon]::Error }
        default { [System.Windows.Forms.MessageBoxIcon]::Information }
    }
    
    return [System.Windows.Forms.MessageBox]::Show($Message, $Title, $ButtonType, $IconType)
}

function Test-PowerShellInstallation {
    # Check PowerShell 7+
    try {
        $pwshVersion = & pwsh -Command '$PSVersionTable.PSVersion.ToString()' 2>$null
        if ($pwshVersion) {
            return @{ Found = $true; Version = $pwshVersion; Command = "pwsh" }
        }
    } catch {}
    
    # Check PowerShell 5.1
    try {
        $psVersion = & powershell -Command '$PSVersionTable.PSVersion.ToString()' 2>$null
        if ($psVersion -and $psVersion -ge "5.1") {
            return @{ Found = $true; Version = $psVersion; Command = "powershell" }
        }
    } catch {}
    
    return @{ Found = $false; Version = $null; Command = $null }
}

function Install-PowerShellViaWinGet {
    try {
        # Check WinGet availability
        $null = & winget --version 2>$null
        if ($LASTEXITCODE -ne 0) {
            Show-MessageBox "WinGet is not available on this system.`n`nPlease install PowerShell manually from:`n• Microsoft Store: Search for 'PowerShell'`n• https://github.com/PowerShell/PowerShell/releases" "WinGet Not Available" "Error"
            return $false
        }
        
        # Install PowerShell
        $result = & winget install Microsoft.PowerShell --accept-source-agreements --accept-package-agreements
        
        if ($LASTEXITCODE -eq 0) {
            Show-MessageBox "PowerShell has been installed successfully!`n`nPlease restart this installer to continue." "Installation Complete"
            return $true
        } else {
            Show-MessageBox "PowerShell installation failed.`n`nPlease try manual installation from:`n• Microsoft Store: Search for 'PowerShell'`n• https://github.com/PowerShell/PowerShell/releases" "Installation Failed" "Error"
            return $false
        }
    } catch {
        Show-MessageBox "Error during PowerShell installation: $($_.Exception.Message)" "Installation Error" "Error"
        return $false
    }
}

# Main execution
try {
    # Check PowerShell installation
    $psCheck = Test-PowerShellInstallation
    
    if (-not $psCheck.Found) {
        $response = Show-MessageBox "iRacing Automation requires PowerShell to function.`n`nWould you like to automatically install PowerShell 7?" "PowerShell Required" "Question"
        
        if ($response -eq [System.Windows.Forms.DialogResult]::Yes) {
            if (Install-PowerShellViaWinGet) {
                exit 0  # Success, user should restart
            } else {
                exit 1  # Installation failed
            }
        } else {
            Show-MessageBox "Installation cancelled.`n`nTo install PowerShell manually:`n• Microsoft Store: Search for 'PowerShell'`n• https://github.com/PowerShell/PowerShell/releases" "Installation Cancelled"
            exit 1
        }
    }
    
    # Run the actual installation
    $scriptPath = Join-Path $PSScriptRoot "scripts\Install.ps1"
    
    if (-not (Test-Path $scriptPath)) {
        Show-MessageBox "Installation script not found at: $scriptPath" "File Not Found" "Error"
        exit 1
    }
    
    # Execute installation script
    $process = Start-Process -FilePath $psCheck.Command -ArgumentList "-ExecutionPolicy Bypass", "-NoProfile", "-File", "`"$scriptPath`"" -Wait -PassThru -WindowStyle Normal
    
    if ($process.ExitCode -eq 0) {
        Show-MessageBox "iRacing Automation installation completed successfully!" "Installation Complete"
    } else {
        Show-MessageBox "Installation completed with some issues. Please check the PowerShell window for details." "Installation Warning" "Error"
    }
    
} catch {
    Show-MessageBox "An unexpected error occurred: $($_.Exception.Message)" "Error" "Error"
    exit 1
}