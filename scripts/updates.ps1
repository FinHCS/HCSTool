Install-PackageProvider -Name NuGet -Force

# Check if the PowerShellGet module is installed
if (-not(Get-Module -Name PowerShellGet -ListAvailable)) {
    # Install the PowerShellGet module
    Install-Module -Name PowerShellGet -Force
}
# Import the PowerShellGet module
Import-Module PowerShellGet 

# Check if the PSWindowsUpdate module is installed
if (-not(Get-Module -Name PSWindowsUpdate -ListAvailable)) {
    # Install the PSWindowsUpdate module
    Install-Module -Name PSWindowsUpdate -Force
}

# Import the PSWindowsUpdate module
Import-Module PSWindowsUpdate

# Download and install all updates including drivers
Write-Host "Downloading and installing updates..."
Get-WindowsUpdate -Install -AcceptAll -IgnoreReboot 

# List the updates being installed
Write-Host "Updates being installed:"
Get-WindowsUpdate | Select-Object Title | Format-Table -AutoSize
$filePath = "$env:TEMP\hcsupdate.txt"
if (-not (Test-Path $filePath)) {
    Set-Content -Path $filePath -Value "true" | Out-Null
}

# Prompt the user to press any key to exit
Write-Host "Press any key to exit..."
$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")