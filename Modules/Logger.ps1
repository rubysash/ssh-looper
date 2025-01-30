# Logger.ps1

# Get the main script's directory path
$mainScriptRoot = Split-Path -Parent $PSScriptRoot
$script:LogFile = Join-Path -Path $mainScriptRoot -ChildPath "ServerLoginLog.txt"

function Write-Log {
    param (
        [string]$Message,
        [string]$Type = "INFO"
    )
    
    # Add this debug line to show full path
    Write-Host "Log file location: $([System.IO.Path]::GetFullPath($script:LogFile))"
    
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogMessage = "[$Timestamp] [$Type] $Message"
    
    # Create log file if it doesn't exist
    if (-not (Test-Path $script:LogFile)) {
        New-Item -Path $script:LogFile -ItemType File -Force | Out-Null
    }
    
    # Write to log file
    Add-Content -Path $script:LogFile -Value $LogMessage
    
    # Output to console for debugging
    Write-Host $LogMessage
}

function Show-LogViewer {
    $logWindow = [Windows.Markup.XamlReader]::Parse(@"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Log Viewer" Height="500" Width="800" WindowStartupLocation="CenterOwner">
    <Grid Margin="10">
        <TextBox Name="LogContent" IsReadOnly="True" TextWrapping="Wrap" 
                 VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Auto"/>
    </Grid>
</Window>
"@)

    $logContent = $logWindow.FindName("LogContent")
    
    if (Test-Path $script:LogFile) {
        $logContent.Text = Get-Content $script:LogFile -Raw
    } else {
        $logContent.Text = "No log file found."
    }

    $logWindow.ShowDialog()
}
function Get-LoggerFunctions {
    @{
        'Write-Log' = ${function:Write-Log}
        'Show-LogViewer' = ${function:Show-LogViewer}
    }
}