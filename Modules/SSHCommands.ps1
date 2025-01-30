# SSHCommands.ps1

# crude escape for quotes.
# seems to not work well for double quotes
function Format-SSHCommand {
    param (
        [string]$Command
    )
    
    # Escape single quotes with '\''
    $Command = $Command.Replace("'", "'\'''")
    
    # Wrap the entire command in single quotes
    Write-Log "Command: $Command"
    return "'$Command'"
}

# For testing command once before firing to all
function Test-SSHCommand {
    param (
        [string]$Command
    )
    
    $dangerousPatterns = @(
        '^rm\s+-rf',
        '>[^>]\S+',
        '\b(chmod|chown)\s+777\b',
        '`',
        '\$\(',
        '&\s*$'
    )
    
    $warnings = @()
    
    foreach ($pattern in $dangerousPatterns) {
        if ($Command -match $pattern) {
            $warnings += "Warning: Command contains potentially dangerous pattern: $pattern"
        }
    }
    
    # Check quotes
    $singleQuotes = ($Command.ToCharArray() | Where-Object { $_ -eq "'" }).Count
    $doubleQuotes = ($Command.ToCharArray() | Where-Object { $_ -eq '"' }).Count
    
    if ($singleQuotes % 2 -ne 0) {
        $warnings += "Warning: Unmatched single quotes"
    }
    if ($doubleQuotes % 2 -ne 0) {
        $warnings += "Warning: Unmatched double quotes"
    }
    
    return $warnings
}

# attempts to parse command
# does not handle nested quotes well
function Execute-SSHCommand {
    param (
        [string]$Server,
        [string]$Username,
        [string]$Password,
        [string]$Command,
        [string]$Port
    )
    
    try {
        $scriptPath = $PSScriptRoot
        if (-not $scriptPath) {
            $scriptPath = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
        }
        
        $plinkPath = Join-Path -Path $scriptPath -ChildPath "plink.exe"
        
        if (-not (Test-Path $plinkPath)) {
            throw "Plink.exe not found at: $plinkPath"
        }
        
        Write-Log "Original command: $Command" -Type "DEBUG"
        
        # Split commands by semicolon or &&
        $commands = $Command -split '[;&]' | Where-Object { $_ -match '\S' }
        $allOutput = @()
        $success = $true
        
        foreach ($cmd in $commands) {
            # Trim each command
            $cmd = $cmd.Trim()
            
            # Format command with bash -c
            $escapedCommand = "bash -c '$($cmd.Replace("'", "'\''"))'"
            Write-Log "Escaped command: $escapedCommand" -Type "DEBUG"
            Write-Log "Full plink command: $plinkPath -ssh -P $Port -l $Username -pw [REDACTED] $Server $escapedCommand" -Type "DEBUG"
            
            Write-Log "Executing command on $Server using port $Port" -Type "DEBUG"
            
            $result = & $plinkPath -ssh -P $Port -l $Username -pw $Password $Server $escapedCommand 2>&1
            Write-Log "RESULT: $result" -Type "DEBUG"
            
            if ($LASTEXITCODE -ne 0) {
                $success = $false
                $allOutput += "Failed executing '$cmd': $result"
            } else {
                $allOutput += $result
            }
        }
        
        return @{
            Success = $success
            Output = $allOutput -join "`n"
            Error = if (-not $success) { $allOutput -join "`n" } else { $null }
        }
    }
    catch {
        return @{
            Success = $false
            Output = $null
            Error = $_.Exception.Message
        }
    }
}

# Execute Command on all servers
function Execute-CommandOnAllServers {
    param (
        [string]$Command,
        [string]$Password
    )
    
    Write-Log "Debug: Starting Execute-CommandOnAllServers"
    
    # Verify we have servers loaded
    if ($null -eq $script:servers -or $script:servers.Count -eq 0) {
        [System.Windows.MessageBox]::Show("No servers available to execute command.", "Error", "OK", "Error")
        return
    }
    
    $warnings = Test-SSHCommand -Command $Command
    if ($warnings.Count -gt 0) {
        $warningMessage = $warnings -join "`n"
        $proceed = [System.Windows.MessageBox]::Show(
            "$warningMessage`n`nDo you want to proceed?",
            "Command Warnings",
            "YesNo",
            "Warning"
        )
        if ($proceed -eq "No") {
            return
        }
    }
    
    Write-Log "Debug: Processing $($script:servers.Count) servers"
    
    foreach ($server in $script:servers) {
        Write-Log "Debug: Processing server $($server.Hostname)"
        
        # Update status directly on server object
        $server.Status = "Running..."
        
        $result = Execute-SSHCommand -Server $server.Hostname `
                                   -Username $server.Username `
                                   -Password $Password `
                                   -Port $server.Port `
                                   -Command $Command
        
        if ($result.Success) {
            $server.Status = "Success"
            $server.Output = $result.Output
            Write-Log "Command succeeded on $($server.Hostname)"
        } else {
            $server.Status = "Failed"
            $server.Output = $result.Error
            Write-Log "Command failed on $($server.Hostname): $($result.Error)" -Type "ERROR"
        }
    }
    
    # Force UI refresh
    if ($script:serversGrid) {
        $script:serversGrid.Items.Refresh()
    }
    
    Show-ExecutionResults
}

# Updated Test-CommandOnFirstServer function
function Test-CommandOnFirstServer {
    param (
        [string]$Command,
        [string]$Password,
        [array]$Servers  # Add this parameter
    )
    
    Write-Log "Debug: Entering Test-CommandOnFirstServer"
    
    # Use passed in servers instead of trying to get from grid
    Write-Log "Debug: Servers array is null? $($null -eq $Servers)"
    if ($Servers) {
        Write-Log "Debug: Servers count: $($Servers.Count)"
    }
    
    # Verify we have servers loaded
    if ($null -eq $Servers -or $Servers.Count -eq 0) {
        [System.Windows.MessageBox]::Show("No servers available to test command.", "Error", "OK", "Error")
        return
    }
    
    $server = $Servers[0]
    Write-Log "Testing command on server: $($server.Hostname)"
    
    $result = Execute-SSHCommand -Server $server.Hostname `
                               -Username $server.Username `
                               -Password $Password `
                               -Port $server.Port `
                               -Command $Command

    $xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Test Result" Height="400" Width="600" WindowStartupLocation="CenterOwner">
    <Grid Margin="10">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>
        
        <TextBlock Text="Test Results" FontWeight="Bold"/>
        <TextBox Grid.Row="1" Margin="0,10" TextWrapping="Wrap" 
                 IsReadOnly="True" VerticalScrollBarVisibility="Auto"
                 Name="ResultText"/>
        <Button Grid.Row="2" Content="Close" HorizontalAlignment="Right" 
                Padding="20,5" Name="CloseButton"/>
    </Grid>
</Window>
"@

    try {
        Add-Type -AssemblyName PresentationFramework
        $testWindow = [Windows.Markup.XamlReader]::Parse($xaml)
        
        # Set the result text
        $resultText = $testWindow.FindName("ResultText")
        if ($result.Success) {
            $resultText.Text = "SUCCESS`n`nServer: $($server.Hostname)`nOutput:`n$($result.Output)"
        } else {
            $resultText.Text = "FAILED`n`nServer: $($server.Hostname)`nError:`n$($result.Error)"
        }

        # Handle close button
        $closeButton = $testWindow.FindName("CloseButton")
        $closeButton.Add_Click({
            $testWindow.Close()
        })

        # Set owner window
        $testWindow.Owner = [System.Windows.Application]::Current.MainWindow

        # Show the window
        [void]$testWindow.ShowDialog()
        
    } catch {
        Write-Log "Error displaying test results: $($_.Exception.Message)" -Type "ERROR"
        [System.Windows.MessageBox]::Show(
            "Error displaying results window. Check the log for details.",
            "Error",
            "OK",
            "Error"
        )
    }
}

Export-ModuleMember -Function Format-SSHCommand, Test-SSHCommand, Execute-SSHCommand, 
                            Execute-CommandOnAllServers, Test-CommandOnFirstServer