# iRacing Automation

**Streamline your iRacing experience with automated application management and professional Stream Deck integration.**

## What This Project Does

iRacing Automation is a comprehensive toolset that simplifies the management of all your iRacing-related applications through a single, automated workflow. Instead of manually launching each program every time you race, this project:

### 🎯 **Core Features:**
- **Automated Application Discovery** - Scans your system for iRacing applications and validates installation paths
- **Professional Icon Generation** - Extracts program icons and creates color-coded overlay variants for different actions
- **Stream Deck Integration** - Generates ready-to-use batch files and provides visual setup instructions
- **Smart Window Management** - Handles programs with dynamic window titles (like Crew Chief and MarvinsAIRA)
- **One-Click Control** - Start all applications, stop all applications, or manage individual programs

### 🖥️ **Stream Deck Benefits:**
- **Visual Button Layout** - Each application gets Focus, Restart, Start, and Stop buttons with distinctive overlay icons
- **Copy-Paste Setup** - Generated HTML guide with copy buttons for easy Stream Deck configuration  
- **Color-Coded Actions** - Blue for Focus, Orange for Restart, Green for Start, Red for Stop
- **Professional Icons** - 144x144 PNG icons with high-contrast overlays optimized for high-resolution displays

### 🔧 **Supported Applications:**
- **iRacing UI** - The main simulator interface
- **Crew Chief** - Voice spotter and race engineer
- **MarvinsAIRA** - AI-powered race assistant  
- **Trading Paints** - Custom car livery manager
- **Racelab Apps** - Telemetry and race analysis tools
- **+ Any additional applications** you want to include

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
- Extracts 144x144 PNG icons from program executables
- Creates HTML setup guide with absolute paths

## Generated Files

After installation:
- `config/programs.json` - Your validated program configuration
- `shell/*.bat` - Stream Deck action files with absolute paths
- `icons/*.png` - Extracted program icons (144x144)
- `StreamDeckInstructions.html` - Visual setup guide
- `logs/install_*.log` - Installation log

## Available Scripts

- `StartAllPrograms.ps1` - Launch all configured programs
- `StopAllPrograms.ps1` - Close all configured programs  
- `StartProgram.ps1 -ProgramName "Name"` - Launch specific program
- `StopProgram.ps1 -ProgramName "Name"` - Close specific program
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

### Window Title Configuration
Some programs have dynamic window titles that include variable information like version numbers or status. For these programs, use partial matching:

#### Programs with Dynamic Window Titles:
- **Crew Chief**: Title changes to "Crew Chief - Active Profile: defaultSettings - Running iRacing"
- **MarvinsAIRA**: Title changes to "Marvin's Awesome iRacing App 1.13.0.0.0" (includes version)

#### Partial Matching Example:
```json
{
  "name": "CrewChiefV4",
  "executableName": "CrewChiefV4.exe",
  "paths": [
    "C:\\Program Files (x86)\\Britton IT Ltd\\CrewChiefV4\\CrewChiefV4.exe"
  ],
  "windowTitle": "Crew Chief",
  "partialMatch": true
}
```

#### Window Title Guidelines:
- **Exact matching** (default): Use the complete window title for programs with static titles
- **Partial matching**: Set `"partialMatch": true` and use only the beginning portion of the title that doesn't change
- **Focus functionality**: The `FocusWindow.ps1` script will find windows that start with the specified title when `partialMatch` is enabled

## Requirements

- Windows PowerShell 5.1 or PowerShell Core
- Stream Deck software
- Programs listed in `programs-init.json` (or manual path configuration during install)

## License
[MIT](./LICENSE)
