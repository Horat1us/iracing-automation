# iRacing Automation

Automation tools for managing iRacing-related applications with Stream Deck integration.

## Quick Start

1. **Clone the repository:**
   ```bash
   git clone https://github.com/horat1us/iracing-automation.git
   cd iracing-automation
   ```

2. **Run the installation script:**
   ```powershell
   .\scripts\Install.ps1
   ```

3. **Configure Stream Deck:**
   - Open `StreamDeckInstructions.html` in your browser
   - Follow the visual guide to set up buttons

## What Install.ps1 Does

- Validates program paths from `config/programs-init.json`
- Prompts for manual path correction if programs aren't found
- Allows adding additional programs interactively
- Generates bat files for Stream Deck integration
- Extracts 72x72 PNG icons from program executables
- Creates HTML setup guide with absolute paths

## Generated Files

After installation:
- `config/programs.json` - Your validated program configuration
- `shell/*.bat` - Stream Deck action files with absolute paths
- `icons/*.png` - Extracted program icons (72x72)
- `StreamDeckInstructions.html` - Visual setup guide
- `logs/install_*.log` - Installation log

## Available Scripts

- `StartAllPrograms.ps1` - Launch all configured programs
- `StopAllPrograms.ps1` - Close all configured programs  
- `RestartProgram.ps1 -ProgramName "Name"` - Restart specific program
- `FocusWindow.ps1 -ProgramName "Name"` - Focus specific program window

## Contributing - Configuring programs-init.json

When adding new programs to `config/programs-init.json`, follow these guidelines:

### Path Configuration
- **Multiple paths**: Include all common installation locations for the program
- **Username placeholder**: Use `{USERNAME}` as a placeholder for the Windows username
- **Path priority**: List paths in order of likelihood (most common first)

### Example program entry:
```json
{
  "name": "YourProgram",
  "executableName": "YourProgram.exe",
  "paths": [
    "C:\\Program Files\\YourProgram\\YourProgram.exe",
    "C:\\Users\\{USERNAME}\\AppData\\Local\\Programs\\YourProgram\\YourProgram.exe",
    "C:\\Program Files (x86)\\YourProgram\\YourProgram.exe"
  ],
  "windowTitle": "Your Program Window Title"
}
```

### Path Guidelines:
- **Program Files**: For system-wide installations
- **Program Files (x86)**: For 32-bit programs on 64-bit systems
- **AppData\\Local\\Programs**: For user-specific installations
- **{USERNAME}**: Will be automatically replaced with the actual Windows username during installation

## Requirements

- Windows PowerShell 5.1 or PowerShell Core
- Stream Deck software
- Programs listed in `programs-init.json` (or manual path configuration during install)

## License
[MIT](./LICENSE)
