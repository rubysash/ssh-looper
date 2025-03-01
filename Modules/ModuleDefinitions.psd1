@{
    # Script module or binary module file associated with this manifest.
    RootModule = 'ModuleDefinitions.psm1'
    
    # Version number of this module.
    ModuleVersion = '1.0.0'
    
    # ID used to uniquely identify this module
    GUID = '12345678-1234-5678-1234-567812345678'
    
    # Author of this module
    Author = 'SSH Command Runner'
    
    # Company or vendor of this module
    CompanyName = 'SSH Command Runner Project'
    
    # Copyright statement for this module
    Copyright = '(c) 2025. All rights reserved.'
    
    # Description of the functionality provided by this module
    Description = 'Module for SSH Command Runner application'
    
    # Minimum version of the Windows PowerShell engine required by this module
    PowerShellVersion = '5.1'
    
    # Name of the Windows PowerShell host required by this module
    PowerShellHostName = ''
    
    # Minimum version of the Windows PowerShell host required by this module
    PowerShellHostVersion = ''
    
    # Functions to export from this module, for best performance, do not use wildcards and do not delete the entry
    FunctionsToExport = @(
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
    
    # Cmdlets to export from this module
    CmdletsToExport = @()
    
    # Variables to export from this module
    VariablesToExport = @()
    
    # Aliases to export from this module
    AliasesToExport = @()
    
    # List of all files packaged with this module
    FileList = @(
        'ModuleDefinitions.psm1',
        'Logger.ps1',
        'ServerManager.ps1',
        'DialogWindows.ps1',
        'SSHCommands.ps1'
    )
    
    # Private data to pass to the module specified in RootModule/ModuleVersion
    PrivateData = @{
        PSData = @{
            # Tags applied to this module for module discovery
            Tags = @('SSH', 'Remote', 'Administration')
            
            # License URI for this module
            LicenseUri = ''
            
            # Project URI for this module
            ProjectUri = ''
            
            # ReleaseNotes of this module
            ReleaseNotes = 'Initial release of SSH Command Runner module'
        }
    }
}