# Import all required PS1 files
$scriptPath = $PSScriptRoot

# Import individual module files
. "$scriptPath\Logger.ps1"
. "$scriptPath\ServerManager.ps1"
. "$scriptPath\DialogWindows.ps1"
. "$scriptPath\SSHCommands.ps1"

# Export all functions specified in the module manifest
Export-ModuleMember -Function @(
    'Write-Log',
    'Show-LogViewer',
    'Import-ServerList',
    'Update-ServerGrid',
    'Show-ExecutionResults',
    'Show-CommandInputDialog',
    'Show-PasswordDialog',
    'Format-SSHCommand',
    'Test-SSHCommand',
    'Execute-SSHCommand',
    'Execute-CommandOnAllServers',
    'Test-CommandOnFirstServer'
)