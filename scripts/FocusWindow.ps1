param(
    [Parameter(Mandatory=$true)]
    [string]$ProgramName
)

# Import Windows API
Add-Type -TypeDefinition @"
    using System;
    using System.Diagnostics;
    using System.Runtime.InteropServices;
    using System.Text;

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

        public delegate bool EnumWindowsDelegate(IntPtr hWnd, IntPtr lParam);
    }
"@

# Import common functions
. (Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Definition) "Common.ps1")

# Load configuration
$Paths = Get-ProjectPaths
$Config = Get-ProgramsConfig -ConfigPath $Paths.ConfigPath

$Program = $Config.programs | Where-Object { $_.name -eq $ProgramName }

if (-not $Program) {
    Write-Host "Программа $ProgramName не найдена в конфигурации"
    exit 1
}

# Searching for program window
$ProcessName = $Program.executableName.Replace('.exe', '')
$Process = Get-Process -Name $ProcessName -ErrorAction SilentlyContinue

if (-not $Process) {
    Write-Host "Программа $ProgramName не запущена"
    exit 1
}

# Make window focused again
foreach ($Proc in $Process) {
    $hWnd = $Proc.MainWindowHandle

    if ($hWnd -ne [IntPtr]::Zero) {
        if ([WindowAPI]::IsIconic($hWnd)) {
            [WindowAPI]::ShowWindow($hWnd, 9) # SW_RESTORE
        }

        [WindowAPI]::SetForegroundWindow($hWnd)
        Write-Host "Window $ProgramName activated"
        exit 0
    }
}

Write-Host "Unable to find main window for program $ProgramName"