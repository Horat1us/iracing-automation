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
    
    # Ensure the log directory exists
    $LogDir = Split-Path -Parent $LogFile
    if (-not (Test-Path $LogDir)) {
        New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
    }
    
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

function Get-ExecutableNameFromPath {
    param([string]$Path)
    
    if ([string]::IsNullOrWhiteSpace($Path)) {
        throw "No path provided"
    }
    
    # Extract the executable name from the path
    $ExecutableName = Split-Path -Leaf $Path
    
    return $ExecutableName
}

function Get-ExecutableNameFromPaths {
    param([array]$Paths)
    
    if (-not $Paths -or $Paths.Count -eq 0) {
        throw "No paths provided"
    }
    
    # Extract the executable name from the first path
    $FirstPath = $Paths[0]
    $ExecutableName = Split-Path -Leaf $FirstPath
    
    return $ExecutableName
}

function Find-WindowByTitle {
    param(
        [string]$WindowTitle,
        [bool]$PartialMatch = $false,
        [string]$ProcessName = $null
    )
    
    # Import Windows API if not already loaded
    try {
        [WindowAPI] | Out-Null
    } catch {
        Add-Type -TypeDefinition @"
            using System;
            using System.Diagnostics;
            using System.Runtime.InteropServices;
            using System.Text;
            using System.Collections.Generic;

            public class WindowAPI {
                [DllImport("user32.dll")]
                public static extern bool SetForegroundWindow(IntPtr hWnd);

                [DllImport("user32.dll")]
                public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);

                [DllImport("user32.dll")]
                public static extern bool IsIconic(IntPtr hWnd);

                [DllImport("user32.dll", CharSet = CharSet.Unicode)]
                public static extern IntPtr FindWindow(string lpClassName, string lpWindowName);

                [DllImport("user32.dll", CharSet = CharSet.Unicode)]
                public static extern int GetWindowText(IntPtr hWnd, StringBuilder sb, int nMaxCount);

                [DllImport("user32.dll")]
                public static extern bool EnumWindows(EnumWindowsDelegate lpEnumFunc, IntPtr lParam);

                [DllImport("user32.dll")]
                public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);

                public delegate bool EnumWindowsDelegate(IntPtr hWnd, IntPtr lParam);

                public static List<IntPtr> FindWindowsByTitle(string title, bool partialMatch, string processName) {
                    List<IntPtr> windows = new List<IntPtr>();
                    
                    EnumWindows(delegate(IntPtr hWnd, IntPtr param) {
                        StringBuilder windowTitle = new StringBuilder(256);
                        GetWindowText(hWnd, windowTitle, windowTitle.Capacity);
                        
                        string currentTitle = windowTitle.ToString();
                        bool titleMatches = false;
                        
                        if (partialMatch) {
                            titleMatches = currentTitle.StartsWith(title, StringComparison.OrdinalIgnoreCase);
                        } else {
                            titleMatches = string.Equals(currentTitle, title, StringComparison.OrdinalIgnoreCase);
                        }
                        
                        if (titleMatches) {
                            // If process name is specified, verify the window belongs to that process
                            if (!string.IsNullOrEmpty(processName)) {
                                uint processId;
                                GetWindowThreadProcessId(hWnd, out processId);
                                
                                try {
                                    Process process = Process.GetProcessById((int)processId);
                                    if (process.ProcessName.Equals(processName, StringComparison.OrdinalIgnoreCase)) {
                                        windows.Add(hWnd);
                                    }
                                } catch {
                                    // Process might have exited, ignore
                                }
                            } else {
                                windows.Add(hWnd);
                            }
                        }
                        
                        return true; // Continue enumeration
                    }, IntPtr.Zero);
                    
                    return windows;
                }
            }
"@
    }
    
    $processNameOnly = if ($ProcessName) { $ProcessName.Replace('.exe', '') } else { $null }
    $windows = [WindowAPI]::FindWindowsByTitle($WindowTitle, $PartialMatch, $processNameOnly)
    
    return $windows
}