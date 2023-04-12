


param([switch]$Elevated)

function Test-Admin {
    $currentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
    $currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

if ((Test-Admin) -eq $false)  {
    if ($elevated) {
        # tried to elevate, did not work, aborting
    } else {
        Start-Process powershell.exe -Verb RunAs -ArgumentList ('-noprofile -noexit -file "{0}" -elevated' -f ($myinvocation.MyCommand.Definition))
    }
    exit
}

'Elevating Powershell to admin'


Copy-Item -Force -Path "$PSScriptRoot\Harpenden Computer Services" -Destination "C:\Program Files" -Recurse

'Copied folder to Program Files'

$TargetFile = "$env:C:\Program Files\Harpenden Computer Services\HCS Remote Support.exe"
$ShortcutFile = "$env:Public\Desktop\HCS Remote Support.lnk"
$WScriptShell = New-Object -ComObject WScript.Shell
$Shortcut = $WScriptShell.CreateShortcut($ShortcutFile)
$Shortcut.TargetPath = $TargetFile
$shortcut.IconLocation = "C:\Program Files\Harpenden Computer Services\HCS.ico"
$Shortcut.Save()


'Created Shortcut on Desktop'

'Changed Icon'

Copy-Item -Force -Path "$env:Public\Desktop\HCS Remote Support.lnk" -Destination 'C:\ProgramData\Microsoft\Windows\Start Menu\Programs'

'Created Start Menu Shortcut'

'Opening Shortcut'




invoke-item 'C:\Program Files\Harpenden Computer Services\HCS Remote Support.exe'

Exit


