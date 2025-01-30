# MainWindow.ps1

# Check for WPF support
try {
    Add-Type -AssemblyName PresentationFramework
    Add-Type -AssemblyName PresentationCore
    Add-Type -AssemblyName WindowsBase
} catch {
    Write-Error "Failed to load WPF assemblies. .NET Framework 4.0 or higher is required."
    exit 1
}

# Get the script's directory path
$scriptPath = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition

# Import required module - using correct path to Modules directory
$modulePath = Join-Path -Path $scriptPath -ChildPath "Modules\ModuleDefinitions.psd1"

# Import module with error handling
try {
    Import-Module $modulePath -Force -DisableNameChecking -ErrorAction Stop
    Write-Log "Module imported successfully from: $modulePath"
} catch {
    Write-Error "Failed to import module: $_"
    exit 1
}

# Initialize script scope variables
$script:currentCommand = $null
$script:password = $null
$script:serversGrid = $null
$script:servers = $null

# to help show formatting of known commands
function Show-CommandExamples {
    $helpWindow = [Windows.Markup.XamlReader]::Parse(@"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Command Examples" Height="600" Width="800" WindowStartupLocation="CenterOwner">
    <Grid Margin="10">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <TextBlock Text="SSH Command Examples" FontSize="16" FontWeight="Bold" Margin="0,0,0,10"/>
        
        <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Auto">
            <StackPanel Name="CommandsPanel" Margin="0,0,0,10">
                <!-- Commands will be added here dynamically -->
            </StackPanel>
        </ScrollViewer>

        <Button Grid.Row="2" Content="Close" HorizontalAlignment="Right" 
                Padding="20,5" Name="CloseButton"/>
    </Grid>
</Window>
"@)

    # Get the correct directory path
    $mainScriptRoot = "D:\v\ps\allservers"  # Explicit path
    Write-Log "Looking for help.json in: $mainScriptRoot"
    $helpJsonPath = Join-Path -Path $mainScriptRoot -ChildPath "help.json"

    try {
        # Debug logging
        Write-Log "Attempting to read help.json from: $helpJsonPath"
        
        # Check if file exists
        if (-not (Test-Path $helpJsonPath)) {
            Write-Log "help.json not found at: $helpJsonPath" -Type "ERROR"
            throw "help.json file not found"
        }
        
        # Read the content with debug logging
        $rawContent = Get-Content -Path $helpJsonPath -Raw
        Write-Log "Raw content read successfully. First 100 characters: $($rawContent.Substring(0, [Math]::Min(100, $rawContent.Length)))"
        
        # Parse JSON with debug logging
        $helpContent = $rawContent | ConvertFrom-Json
        Write-Log "JSON parsed successfully. Found $($helpContent.commandExamples.Count) command examples"

        $commandsPanel = $helpWindow.FindName("CommandsPanel")
        
        # Add each command example to the panel
        foreach ($example in $helpContent.commandExamples) {
            # Create container for each example
            $examplePanel = New-Object System.Windows.Controls.StackPanel
            $examplePanel.Margin = New-Object System.Windows.Thickness(0, 0, 0, 20)

            # Add title
            $titleBlock = New-Object System.Windows.Controls.TextBlock
            $titleBlock.Text = $example.title
            $titleBlock.FontWeight = "Bold"
            $titleBlock.FontSize = 14
            $titleBlock.Margin = New-Object System.Windows.Thickness(0, 0, 0, 5)
            $examplePanel.Children.Add($titleBlock)

            # Add description
            $descBlock = New-Object System.Windows.Controls.TextBlock
            $descBlock.Text = $example.description
            $descBlock.TextWrapping = "Wrap"
            $descBlock.Margin = New-Object System.Windows.Thickness(0, 0, 0, 5)
            $examplePanel.Children.Add($descBlock)

            # Add command in a border with monospace font
            $border = New-Object System.Windows.Controls.Border
            $border.Background = "#f0f0f0" | ConvertFrom-String
            $border.Padding = New-Object System.Windows.Thickness(10)
            $border.Margin = New-Object System.Windows.Thickness(0, 5, 0, 0)

            $commandBlock = New-Object System.Windows.Controls.TextBox
            $commandBlock.Text = $example.command
            $commandBlock.FontFamily = "Consolas"
            $commandBlock.IsReadOnly = $true
            $commandBlock.TextWrapping = "Wrap"
            $commandBlock.Background = "Transparent"
            $commandBlock.BorderThickness = New-Object System.Windows.Thickness(0)

            $border.Child = $commandBlock
            $examplePanel.Children.Add($border)

            # Add a button to use this command
            #$useButton = New-Object System.Windows.Controls.Button
            #$useButton.Content = "Use This Command"
            #$useButton.Margin = New-Object System.Windows.Thickness(0, 5, 0, 0)
            #$useButton.HorizontalAlignment = "Left"
            #$useButton.Padding = New-Object System.Windows.Thickness(10, 5, 10, 5)

            # Add click handler for the button
            #$useButton.Add_Click({
            #    $script:currentCommand = $example.command
            #    Write-Log "Command example selected: $($example.title)"
            #    $helpWindow.Close()

                # Show confirmation to user
            #    [System.Windows.MessageBox]::Show(
            #        "Command has been loaded. Click 'Execute Command' to run it.",
            #        "Command Loaded",
            #        [System.Windows.MessageBoxButton]::OK,
            #        [System.Windows.MessageBoxImage]::Information
            #    )
            #}.GetNewClosure())

            #$examplePanel.Children.Add($useButton)

            # Add separator
            $separator = New-Object System.Windows.Controls.Separator
            $separator.Margin = New-Object System.Windows.Thickness(0, 10, 0, 10)
            $examplePanel.Children.Add($separator)

            $commandsPanel.Children.Add($examplePanel)
        }

        # Handle close button
        $closeButton = $helpWindow.FindName("CloseButton")
        $closeButton.Add_Click({
            $helpWindow.Close()
        })

        # Show the window modally
        $helpWindow.Owner = [System.Windows.Application]::Current.MainWindow
        $helpWindow.ShowDialog()
    }
    catch {
        Write-Log "Error displaying command examples: $($_.Exception.Message)" -Type "ERROR"
        [System.Windows.MessageBox]::Show(
            "Error loading command examples. Please check if help.json exists and is properly formatted.",
            "Error",
            [System.Windows.MessageBoxButton]::OK,
            [System.Windows.MessageBoxImage]::Error
        )
    }
}

# truncates the log file, then logs it was reset
function Remove-LogFile {
    try {
        # Get the directory where MainWindow.ps1 is located
        $scriptDir = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
        $logFile = Join-Path -Path "D:\v\ps\allservers" -ChildPath "ServerLoginLog.txt"
        
        Write-Log "DEBUG: Script directory: $scriptDir" -Type "DEBUG"
        Write-Log "DEBUG: Full log file path: $logFile" -Type "DEBUG"
        
        if (Test-Path $logFile) {
            Set-Content -Path $logFile -Value $null -Force
            Write-Log "Log file cleared successfully: $logFile"
            [System.Windows.MessageBox]::Show(
                "Log file cleared successfully.",
                "Success",
                [System.Windows.MessageBoxButton]::OK,
                [System.Windows.MessageBoxImage]::Information
            )
        } else {
            Write-Log "DEBUG: Log file NOT found at: $logFile" -Type "DEBUG"
            [System.Windows.MessageBox]::Show(
                "No log file found at: $logFile",
                "Information",
                [System.Windows.MessageBoxButton]::OK,
                [System.Windows.MessageBoxImage]::Information
            )
        }
    } catch {
        Write-Error "Error clearing log file: $($_.Exception.Message)"
        Write-Log "DEBUG: Error stack trace: $($_.ScriptStackTrace)" -Type "ERROR"
        [System.Windows.MessageBox]::Show(
            "Failed to clear log file: $($_.Exception.Message)",
            "Error",
            [System.Windows.MessageBoxButton]::OK,
            [System.Windows.MessageBoxImage]::Error
        )
    }
}

# setup the xaml frame/buttons etc
function Initialize-MainWindow {
    param()
    
    try {
        # Create XAML for the window
        [xml]$xaml = @"
<Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="SSH Command Runner"
    Height="600"
    Width="1000"
    WindowStartupLocation="CenterScreen"
    ResizeMode="CanResizeWithGrip">
    <Grid>
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="2*"/>
            <ColumnDefinition Width="*"/>
        </Grid.ColumnDefinitions>
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
        </Grid.RowDefinitions>

        <TextBlock Text="Server List and Results" FontSize="16" FontWeight="Bold" Margin="10,5,10,5" Grid.Column="0" Grid.Row="0"/>
        <TextBlock Text="Controls" FontSize="16" FontWeight="Bold" Margin="10,5,10,5" Grid.Column="1" Grid.Row="0"/>

        <DataGrid x:Name="ServersGrid" Grid.Column="0" Grid.Row="1" Margin="10" AutoGenerateColumns="False" IsReadOnly="True">
            <DataGrid.Columns>
                <DataGridTextColumn Header="Hostname" Binding="{Binding Hostname}" Width="*"/>
                <DataGridTextColumn Header="Username" Binding="{Binding Username}" Width="*"/>
                <DataGridTextColumn Header="Role" Binding="{Binding Role}" Width="*"/>
                <DataGridTextColumn Header="Status" Binding="{Binding Status}" Width="*"/>
            </DataGrid.Columns>
        </DataGrid>

        <StackPanel Grid.Column="1" Grid.Row="1" Margin="10">
            <Button x:Name="EnterCommandBtn" Content="Enter Command" Margin="0,5,0,5" Padding="5"/>
            <Button x:Name="ExecuteCommandBtn" Content="Execute Command" Margin="0,5,0,5" Padding="5"/>
            <Button x:Name="TestCommandBtn" Content="Test Command" Margin="0,5,0,5" Padding="5"/>
            <Button x:Name="ViewLogBtn" Content="View Log" Margin="0,5,0,5" Padding="5"/>
            <Button x:Name="DeleteLogBtn" Content="Delete Log" Margin="0,5,0,5" Padding="5"/>
            <Button x:Name="ShowExamplesBtn" Content="Command Examples" Margin="0,5,0,5" Padding="5"/>
        </StackPanel>
    </Grid>
</Window>
"@

        # Parse the XAML
        try {
            $reader = [System.Xml.XmlNodeReader]::new($xaml)
            $window = [System.Windows.Markup.XamlReader]::Load($reader)
            
            if ($null -eq $window) {
                throw "Failed to create window from XAML"
            }
            
            Write-Log "Successfully created window from XAML"
        }
        catch {
            Write-Log "Failed to parse XAML or create window: $($_.Exception.Message)" -Type "ERROR"
            throw
        }

        # Load servers first - this will initialize $script:servers
        $script:servers = Import-ServerList
        
        if ($null -eq $script:servers -or $script:servers.Count -eq 0) {
            Write-Warning "No servers were loaded. Please check your servers.csv file."
            return $window
        }

        Write-Log "Initializing main window with $($script:servers.Count) servers"

        # Get references to controls and validate them
        $script:serversGrid = $window.FindName('ServersGrid')
        if ($null -eq $script:serversGrid) {
            Write-Log "Failed to find ServersGrid control" -Type "ERROR"
            throw "Critical UI control not found: ServersGrid"
        }
        $enterCommandBtn = $window.FindName('EnterCommandBtn')
        $executeCommandBtn = $window.FindName('ExecuteCommandBtn')
        $testCommandBtn = $window.FindName('TestCommandBtn')
        $viewLogBtn = $window.FindName('ViewLogBtn')
        $deleteLogBtn = $window.FindName('DeleteLogBtn')

        # Validate grid initialization state
        if ($null -eq $script:serversGrid) {
            Write-Log "ServersGrid control is null" -Type "ERROR"
            throw "ServersGrid initialization failed"
        }
        
        # Set ItemsSource for servers grid with validation
        if ($script:serversGrid -and $script:servers) {
            Write-Log "Setting servers grid ItemsSource with $($script:servers.Count) servers"
            Write-Log "Debug: Servers collection type before setting: $($script:servers.GetType().FullName)"
            $script:serversGrid.ItemsSource = $script:servers
            Write-Log "Debug: Grid ItemsSource type after setting: $($script:serversGrid.ItemsSource.GetType().FullName)"
            Write-Log "Debug: Grid ItemsSource count after setting: $($script:serversGrid.ItemsSource.Count)"
        }

        # Add button click handlers
        $enterCommandBtn.Add_Click({
            $commandDialog = Show-CommandInputDialog
            if ($commandDialog.DialogResult) {
                $script:currentCommand = $commandDialog.CommandText
                Write-Log "New command entered: $($script:currentCommand)"
            }
        })

        $executeCommandBtn.Add_Click({
            if (-not $script:currentCommand) {
                Write-Warning "Please enter a command first."
                return
            }

            if (-not $script:password) {
                $passwordDialog = Show-PasswordDialog
                if ($passwordDialog.DialogResult) {
                    $script:password = $passwordDialog.Password
                } else {
                    return
                }
            }

            Write-Log "Executing command on all servers: $($script:currentCommand)"
            try {
                Execute-CommandOnAllServers $script:currentCommand $script:password
            }
            catch {
                Write-Log "Failed to execute command on servers: $($_.Exception.Message)" -Type "ERROR"
                Write-Error "Failed to execute command: $($_.Exception.Message)"
            }
        })

        $testCommandBtn.Add_Click({
            if (-not $script:currentCommand) {
                Write-Warning "Please enter a command first."
                return
            }
        
            if (-not $script:password) {
                $passwordDialog = Show-PasswordDialog
                if ($passwordDialog.DialogResult) {
                    $script:password = $passwordDialog.Password
                } else {
                    return
                }
            }
        
            Write-Log "Testing command on first server: $($script:currentCommand)"
            try {
                # Pass the servers array to the function
                Test-CommandOnFirstServer $script:currentCommand $script:password $script:servers
            }
            catch {
                Write-Log "Failed to test command: $($_.Exception.Message)" -Type "ERROR"
                Write-Error "Failed to test command: $($_.Exception.Message)"
            }
        })

        $viewLogBtn.Add_Click({
            Show-LogViewer
        })

        # Add click handler for delete log button
        $deleteLogBtn.Add_Click({
            $result = [System.Windows.MessageBox]::Show(
                "Are you sure you want to delete the log file?",
                "Confirm Delete",
                [System.Windows.MessageBoxButton]::YesNo,
                [System.Windows.MessageBoxImage]::Warning
            )
            
            if ($result -eq [System.Windows.MessageBoxResult]::Yes) {
                Remove-LogFile
            }
        })

        $showExamplesBtn = $window.FindName('ShowExamplesBtn')
        $showExamplesBtn.Add_Click({
            Show-CommandExamples
        })

        # Set window close event
        $window.Add_Closed({
            Write-Log "Cleaning up script variables"
            $script:servers = $null
            $script:currentCommand = $null
            $script:password = $null
            $script:serversGrid = $null
        })

        Write-Log "Window creation successful"
        return $window
    }
    catch {
        Write-Log "Error initializing main window: $($_.Exception.Message)" -Type "ERROR"
        Write-Error "Error initializing application: $($_.Exception.Message)"
        throw  # Re-throw the exception to be caught by the main try-catch block
    }
}

# Start the application with proper cleanup
try {
    Write-Log "Starting application initialization"
    
    # Initialize WPF application with proper STA thread
    $app = [System.Windows.Application]::new()
    $app.ShutdownMode = [System.Windows.ShutdownMode]::OnMainWindowClose
    
    # Ensure we're running in STA mode
    if ([System.Threading.Thread]::CurrentThread.GetApartmentState() -ne [System.Threading.ApartmentState]::STA) {
        Write-Log "Restarting in STA mode" -Type "INFO"
        Start-Process powershell.exe -ArgumentList "-STA -File `"$PSCommandPath`"" -NoNewWindow
        exit
    }
    
    Write-Log "Created new WPF Application instance"

    Write-Log "Initializing main window"
    $mainWindow = Initialize-MainWindow
    
    if ($null -ne $mainWindow) {
        Write-Log "Main window created successfully, showing window"
        $app.MainWindow = $mainWindow
        $mainWindow.Show()
        Write-Log "Starting application"
        $app.Run()
    } else {
        Write-Log "Failed to create main window" -Type "ERROR"
        exit 1
    }
} catch {
    Write-Error "Failed to start application: $_"
    Write-Log "Critical error starting application: $_" -Type "ERROR"
    exit 1
}