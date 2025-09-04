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

## Requirements

- Windows PowerShell 5.1 or PowerShell Core
- Stream Deck software
- Programs listed in `programs-init.json` (or manual path configuration during install)

## License
[MIT](./LICENSE)
