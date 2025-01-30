# ServerManager.ps1

class Server {
    [string]$Hostname
    [string]$Username
    [string]$Port
    [string]$Role
    [string]$Description
    [string]$Status
    [string]$Output

    Server([string]$hostname, [string]$username, [string]$port, [string]$role, [string]$description) {
        $this.Hostname = $hostname
        $this.Username = $username
        $this.Port = $port
        $this.Role = $role
        $this.Description = $description
        $this.Status = "Ready"
        $this.Output = ""
    }
}

function Import-ServerList {
    # Get the main script's directory
    $mainScriptRoot = Split-Path -Parent $PSScriptRoot
    $ServersCSV = Join-Path -Path $mainScriptRoot -ChildPath "servers.csv"
    
    if (-not (Test-Path $ServersCSV)) {
        Write-Log "The file '$ServersCSV' does not exist." -Type "ERROR"
        [System.Windows.MessageBox]::Show("servers.csv not found at: $ServersCSV", "Error", "OK", "Error")
        return @()
    }
    
    try {
        $csvServers = Import-Csv -Path $ServersCSV
        $script:servers = [System.Collections.ObjectModel.ObservableCollection[object]]::new()
        
        foreach ($csvServer in $csvServers) {
            $server = [Server]::new(
                $csvServer.Hostname,
                $csvServer.Username,
                $csvServer.Port,
                $csvServer.Role,
                $csvServer.Description
            )
            $script:servers.Add($server)
        }
        
        Write-Log "Loaded $($script:servers.Count) servers from $ServersCSV"
        return $script:servers
    }
    catch {
        Write-Log "Error reading CSV file: $($_.Exception.Message)" -Type "ERROR"
        [System.Windows.MessageBox]::Show(
            "Error reading servers.csv`n$($_.Exception.Message)",
            "Error",
            [System.Windows.MessageBoxButton]::OK,
            [System.Windows.MessageBoxImage]::Error
        )
        return @()
    }
}

function Update-ServerGrid {
    param (
        [array]$Servers
    )
    
    $script:servers = $Servers
    $script:serversGrid.ItemsSource = $Servers
}

function Show-ExecutionResults {
    $resultsWindow = [Windows.Markup.XamlReader]::Parse(@"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Command Execution Results" Height="600" Width="800" WindowStartupLocation="CenterOwner">
    <Grid Margin="10">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <TextBlock Text="Command Execution Results" FontSize="16" FontWeight="Bold"/>
        
        <DataGrid Grid.Row="1" Margin="0,10" AutoGenerateColumns="False" 
                  IsReadOnly="True" ItemsSource="{Binding}">
            <DataGrid.Columns>
                <DataGridTextColumn Header="Hostname" Binding="{Binding Hostname}" Width="*"/>
                <DataGridTextColumn Header="Status" Binding="{Binding Status}" Width="100"/>
                <DataGridTextColumn Header="Output" Binding="{Binding Output}" Width="2*"/>
            </DataGrid.Columns>
        </DataGrid>

        <Button Grid.Row="2" Content="Export Results" HorizontalAlignment="Left" 
                Padding="20,5" Name="ExportButton"/>
        <Button Grid.Row="2" Content="Close" HorizontalAlignment="Right" 
                Padding="20,5" Name="CloseButton"/>
    </Grid>
</Window>
"@)

    # Set the DataContext
    $resultsWindow.DataContext = $script:servers

    # Get the buttons
    $exportButton = $resultsWindow.FindName("ExportButton")
    $closeButton = $resultsWindow.FindName("CloseButton")

    # Add button handlers
    $exportButton.Add_Click({
        $saveDialog = New-Object Microsoft.Win32.SaveFileDialog
        $saveDialog.Filter = "CSV files (*.csv)|*.csv|All files (*.*)|*.*"
        $saveDialog.DefaultExt = "csv"
        $saveDialog.FileName = "ServerResults_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
        
        if ($saveDialog.ShowDialog()) {
            $script:servers | Export-Csv -Path $saveDialog.FileName -NoTypeInformation
            Write-Log "Results exported to $($saveDialog.FileName)"
            [System.Windows.MessageBox]::Show(
                "Results exported successfully.",
                "Export Complete",
                [System.Windows.MessageBoxButton]::OK,
                [System.Windows.MessageBoxImage]::Information
            )
        }
    })

    $closeButton.Add_Click({
        $resultsWindow.Close()
    })

    # Show dialog with owner
    $resultsWindow.Owner = [System.Windows.Application]::Current.MainWindow
    $resultsWindow.ShowDialog()
}

Export-ModuleMember -Function Import-ServerList, Update-ServerGrid, Show-ExecutionResults