# PowerShell SSH Command Runner
A PowerShell GUI application for executing commands across multiple SSH servers with password authentication.

## Features
- Windows GUI interface for command execution
- Execute commands across multiple servers simultaneously
- Support for different usernames per server
- Password-based authentication (single password for all servers)
- Command validation and safety checks
- Comprehensive logging
- CSV output for result analysis
- Real-time execution feedback
- Command escaping for complex shell commands
- Built-in warning system for potentially dangerous commands
- Help File with sample command formats
- Simple Log viewing/deleting
- Lots of Debug stuff (Currently)

## Prerequisites
- Windows PowerShell 5.1 or higher
- PuTTY (plink.exe must be in Path/Modules Folder)
- Server list in CSV format
- .NET Framework 4.7.2 or higher (for WPF support)

## Installation
1. Copy all PowerShell scripts to your desired location
2. Create servers.csv in the same directory as MainWindow.ps1
3. Ensure all .ps1 and .psd1 files maintain their relative paths
4. Run Start-ssh-looper.ps1 to start the application

## Required Files
### servers.csv
CSV file containing server information with these headers:

Username,Hostname,Port,Role,Description

Example:
```
Username,Hostname,Port,Role,Description
admin,server1.example.com,22,webserver,Production web server
root,server2.example.com,2222,database,Primary database
```

## File Description
- Start-ssh-looper.ps1 - Calls MainWindow (run this)
- MainWindow.ps1 - Main application window and entry point
- ModuleDefinitions.psd1 - PowerShell module manifest
- ModuleDefinitions.psm1 - PowerShell module loader
- DialogWindows.ps1 - Input dialog implementations
- Logger.ps1 - Logging functionality
- ServerManager.ps1 - Server management functions
- SSHCommands.ps1 - SSH command execution logic

## File Structure

```
ProjectRoot/
│
├── Start-ssh-looper.ps1
├── MainWindow.ps1
├── servers.csv
│
└── Modules/
    ├── ModuleDefinitions.psd1
    ├── ModuleDefinitions.psm1
    ├── DialogWindows.ps1
    ├── Logger.ps1
    ├── ServerManager.ps1
    ├── SSHCommands.ps1
    └── plink.exe
```

## Generated Files
### ServerLoginLog.txt
Detailed execution log containing:
- Timestamp for each action
- Success/failure status
- Error messages
- Command execution details

### ServerResults.csv
Command execution results containing:
- Hostname
- Username
- Role
- Description
- Command executed
- Timestamp
- Success status
- Command output/error message

## Usage
1. Run MainWindow.ps1:
```
.\Start-ssh-looper.ps1
```

2. Use the GUI to:
   - Enter SSH commands
   - Test commands on a single server
   - Execute commands on all servers
   - View execution logs
   - Export results to CSV

## Command Safety Features
(todo)

The script checks for potentially dangerous patterns including:
- rm -rf commands
- Unsafe redirects
- chmod/chown 777
- Backtick usage
- Command substitution
- Background processes
- Unmatched quotes

## Error Handling
- Validates plink.exe availability
- Checks for existence of required files
- Handles SSH connection failures
- Captures and logs command execution errors
- Provides real-time error feedback

## Security Notes
- Password is stored in memory during execution
- Commands are logged in plain text
- CSV output includes command results
- Server credentials are stored in CSV file

## Best Practices
1. Test before executing
2. Review command validation warnings carefully
3. Test commands on non-production servers first
4. Regularly rotate SSH passwords
5. Monitor ServerLoginLog.txt for unusual activity

## Example Commands
```
# Check OS version
cat /etc/os-release | grep VERSION

# List config files
find /opt -name *.conf

# Check processes
ps aux | grep java

# Start other Shells
clish -c 'show configuration' | egrep 'this|that'

# View resources/multi line
df -h; free -m
```

## Known Issues
- Requires same password for all servers
- Does not support key-based authentication (yet)
- Windows-only (PowerShell/WPF requirement/Net 4.0)
- No special characters allowed, except single quotes and pipes

## Contributing
Feel free to submit issues and enhancement requests.

## License
[MIT License](LICENSE)
