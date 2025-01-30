# Start-SSHRunner.ps1
$mainScript = Join-Path $PSScriptRoot "MainWindow.ps1"
$job = Start-Job -ScriptBlock { 
    param($script)
    . $script
} -ArgumentList $mainScript

# Wait for job to complete and get output
Receive-Job -Job $job -Wait
Remove-Job -Job $job