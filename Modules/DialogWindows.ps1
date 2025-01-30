# DialogWindows.ps1

function Show-CommandInputDialog {
    $inputDialog = [Windows.Markup.XamlReader]::Parse(@"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Enter Command" Height="300" Width="500" WindowStartupLocation="CenterOwner">
    <Grid Margin="10">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <TextBlock Text="Enter command to execute:" Margin="0,0,0,5"/>
        
        <TextBox Grid.Row="1" Name="CommandText" AcceptsReturn="True" 
                 TextWrapping="Wrap" VerticalScrollBarVisibility="Auto"
                 FontFamily="Consolas"/>

        <StackPanel Grid.Row="2" Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,10,0,0">
            <Button Content="OK" Name="OKButton" Width="75" Margin="0,0,10,0"/>
            <Button Content="Cancel" Name="CancelButton" Width="75"/>
        </StackPanel>
    </Grid>
</Window>
"@)

    $commandText = $inputDialog.FindName("CommandText")
    $okButton = $inputDialog.FindName("OKButton")
    $cancelButton = $inputDialog.FindName("CancelButton")

    # Add command text to the dialog object
    Add-Member -InputObject $inputDialog -MemberType NoteProperty -Name "CommandText" -Value ""

    $okButton.Add_Click({
        $inputDialog.CommandText = $commandText.Text
        $inputDialog.DialogResult = $true
        $inputDialog.Close()
    })

    $cancelButton.Add_Click({
        $inputDialog.DialogResult = $false
        $inputDialog.Close()
    })

    # Set focus to the text box
    $inputDialog.Add_Loaded({
        $commandText.Focus()
    })

    # Show dialog
    $inputDialog.ShowDialog()

    return $inputDialog
}

function Show-PasswordDialog {
    $passwordDialog = [Windows.Markup.XamlReader]::Parse(@"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Enter Password" Height="150" Width="400" WindowStartupLocation="CenterOwner">
    <Grid Margin="10">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <TextBlock Text="Enter password (same for all servers):" Margin="0,0,0,5"/>
        
        <PasswordBox Grid.Row="1" Name="PasswordBox" Margin="0,0,0,10"/>

        <StackPanel Grid.Row="2" Orientation="Horizontal" HorizontalAlignment="Right">
            <Button Content="OK" Name="OKButton" Width="75" Margin="0,0,10,0"/>
            <Button Content="Cancel" Name="CancelButton" Width="75"/>
        </StackPanel>
    </Grid>
</Window>
"@)

    $passwordBox = $passwordDialog.FindName("PasswordBox")
    $okButton = $passwordDialog.FindName("OKButton")
    $cancelButton = $passwordDialog.FindName("CancelButton")

    # Add password to the dialog object
    Add-Member -InputObject $passwordDialog -MemberType NoteProperty -Name "Password" -Value ""

    $okButton.Add_Click({
        $passwordDialog.Password = $passwordBox.Password
        $passwordDialog.DialogResult = $true
        $passwordDialog.Close()
    })

    $cancelButton.Add_Click({
        $passwordDialog.DialogResult = $false
        $passwordDialog.Close()
    })

    # Set focus to the password box
    $passwordDialog.Add_Loaded({
        $passwordBox.Focus()
    })

    # Show dialog
    $passwordDialog.ShowDialog()

    return $passwordDialog
}

function Get-DialogWindowsFunctions {
    @{
        'Show-CommandInputDialog' = ${function:Show-CommandInputDialog}
        'Show-PasswordDialog' = ${function:Show-PasswordDialog}
    }
}