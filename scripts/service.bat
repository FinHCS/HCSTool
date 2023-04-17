@echo off
title Fin's Service Script Version 2.1
setlocal
if %build% GEQ 22000 (
  echo [%time%] [INFO] System is running Windows 11>> C:\HCSLog.txt  
) else (
  echo [%time%] [INFO] System is running Windows 10>> C:\HCSLog.txt
)


if %build% GEQ 22000 (
  echo Running on Windows 11, not running W10 specific registry tweaks
  goto w11Setting
) else (
  goto w10Setting
)

:w10Setting
echo Operating system is Windows 10
echo opening Ease of Access settings to disable animations
start ms-settings:easeofaccess-display
pause > nul
goto setup



:w11Setting
echo Running on Windows 11, opening Viusal effects settings to disable animations
start ms-settings:easeofaccess-visualeffects
pause > nul
goto setup
:setup

echo Opening Task Manger to disable startup items
start %windir%\system32\Taskmgr.exe /7 /startup			
pause >nul



echo Running Ccleaner Portable 
start "" %~dp0\ccleaner\ccleaner64.exe
pause >nul

where choco > nul 2>&1
if %errorlevel% equ 0 (
	echo [%time%]Prior Chocolatey install detected, skipping installation>> C:\HCSLog.txt
    echo Chocolatey is installed, skipping installation
	echo [%time%]Chocolatey is installed, skipping installation>> C:\HCSLog.txt
	
) else (
    echo Chocolatey is not installed, installing now
	echo [%time%]Chocolatey is not installed, installing now>> C:\HCSLog.txt
)

echo Installing Chocolatey
echo [%time%]Chocolatey not detected, installing now>> C:\HCSLog.txt
:: starts a minimised Powershell window as admin to install chocolatey to install packages later
start /min /wait Powershell.exe -executionpolicy remotesigned -command Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
echo [%time%]Chocolatey installed>> C:\HCSLog.txt


echo | set /p dummy="Refreshing environment variables from registry for cmd.exe. Please wait..."

goto main

:: Set one environment variable from registry key
:SetFromReg
    "%WinDir%\System32\Reg" QUERY "%~1" /v "%~2" > "%TEMP%\_envset.tmp" 2>NUL
    for /f "usebackq skip=2 tokens=2,*" %%A IN ("%TEMP%\_envset.tmp") do (
        echo/set "%~3=%%B"
    )
    goto :EOF

:: Get a list of environment variables from registry
:GetRegEnv
    "%WinDir%\System32\Reg" QUERY "%~1" > "%TEMP%\_envget.tmp"
    for /f "usebackq skip=2" %%A IN ("%TEMP%\_envget.tmp") do (
        if /I not "%%~A"=="Path" (
            call :SetFromReg "%~1" "%%~A" "%%~A"
        )
    )
    goto :EOF

:main
    echo/@echo off >"%TEMP%\_env.cmd"

    :: Slowly generating final file
    call :GetRegEnv "HKLM\System\CurrentControlSet\Control\Session Manager\Environment" >> "%TEMP%\_env.cmd"
    call :GetRegEnv "HKCU\Environment">>"%TEMP%\_env.cmd" >> "%TEMP%\_env.cmd"

    :: Special handling for PATH - mix both User and System
    call :SetFromReg "HKLM\System\CurrentControlSet\Control\Session Manager\Environment" Path Path_HKLM >> "%TEMP%\_env.cmd"
    call :SetFromReg "HKCU\Environment" Path Path_HKCU >> "%TEMP%\_env.cmd"

    :: Caution: do not insert space-chars before >> redirection sign
    echo/set "Path=%%Path_HKLM%%;%%Path_HKCU%%" >> "%TEMP%\_env.cmd"

    :: Cleanup
    del /f /q "%TEMP%\_envset.tmp" 2>nul
    del /f /q "%TEMP%\_envget.tmp" 2>nul

    :: capture user / architecture
    SET "OriginalUserName=%USERNAME%"
    SET "OriginalArchitecture=%PROCESSOR_ARCHITECTURE%"

    :: Set these variables
    call "%TEMP%\_env.cmd"

    :: Cleanup
    del /f /q "%TEMP%\_env.cmd" 2>nul

    :: reset user / architecture
    SET "USERNAME=%OriginalUserName%"
    SET "PROCESSOR_ARCHITECTURE=%OriginalArchitecture%"

    echo | set /p dummy="Finished."
    echo .
 

TIMEOUT /T 5 /nobreak  > nul

echo Installing software
choco feature enable -n=allowGlobalConfirmation
echo [%time%]Enabled global conformation for Chocolatey >> C:\HCSLog.txt
::sets choco to not need conformation to install software
echo Installing utilities and prerequesites
start /min /wait Powershell.exe choco install PSWindowsUpdate setdefaultbrowser -y --ignore-checksums > nul

echo [%time%]Installed PSWindowsUpdate and setdefaultbrowser>> C:\HCSLog.txt

:software
echo Installing Malwarebytes
start /min /wait Powershell.exe choco install malwarebytes -y --ignore-checksums > nul
echo [%time%]Installed Service software >> C:\HCSLog.txt
cd %~dp0
start "" "C:\Program Files\Malwarebytes\Anti-Malware\mbam.exe"


REM choco install office365business --params "'/productid:ProPlus2021Volume /language:en-GB /updates:TRUE /eula:TRUE'"

setdefaultbrowser chrome
echo Setting default browser to Google Chrome
echo [%time%] Setting Default browser to Google Chrome >> C:\HCSLog.txt

echo Disabling  "We are setting up your PC" animation after logon
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v "EnableFirstLogonAnimation" /t REG_DWORD /d "0" /f > nul
echo [%time%] Disabled login animation >> C:\HCSLog.txt

for /f "tokens=2 delims==" %%a in ('wmic os get BuildNumber /value') do set build=%%a
rem Check if the build number is greater than or equal to 10.0.22000.0 as that is the difference between W10/W11

if %build% GEQ 22000 (
  echo Running on Windows 11, not running W10 specific registry tweaks
  goto w11
) else (
  goto w10
  pause > nul
)

:w10

echo Setting the taskbar search bar to "Show search bar"
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" /v "SearchboxTaskbarMode" /t REG_DWORD /d 1 /f > nul


rem Check if the Windows Search key exists
reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows" /f "Windows Search" > nul
if %errorlevel% == 0 (
  echo Windows Search key already exists
) else (
  echo Editing Registry to hide Search Bar
  reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows" /v "Windows Search" /t REG_DWORD /d 0 /f > nul
)

rem Check if the AllowCortana value exists
reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "AllowCortana" > nul
if %errorlevel% == 0 (
  echo AllowCortana value already exists
) else (
  echo Editing Registry to hide Cortana buttonvalue
  reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "AllowCortana" /t REG_DWORD /d 0 /f > nul
)

echo Restarting Windows Search service...
net stop "Windows Search" > nul
net start "Windows Search" > nul

rem Change the registry value for the Explorer window that opens to "This PC"

reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v LaunchTo /t REG_DWORD /d 1 /f > nul
echo Setting Windows Explorer to open to My PC by default
echo Disabling post update "setting up pc" animation
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v EnableFirstLogonAnimation /t REG_DWORD /d 0 /f > nul
    
IF "%darkMode%"=="true" (
	echo Setting dark theme
	reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v "AppsUseLightTheme" /t REG_DWORD /d 0 /f > nul


)

echo Disabling transparency effects
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v "EnableTransparency" /t REG_DWORD /d 0 /f > nul


rem Set the news and interests feed to hidden
REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v ShellFeedsTaskbarViewMode /t REG_DWORD /d 2 /f > nul

echo Taskbar search bar set to "Hide search bar"
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds" /v EnableFeeds /t REG_DWORD /d 0 /f > nul
echo News and interests feed set to hidden

reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v LaunchTo /t REG_DWORD /d 1 /f > nul
echo File explorer set to open to My PC
rem restarts explorer and reopens all open explorer windows 
goto regend


:w11
echo Setting Taskbar Alignment to the left side
reg add "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v TaskbarAl /t REG_DWORD /d 0 /f > nul

echo Hiding Widgets button
reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v TaskbarDa /t REG_DWORD /d 0 /f > nul

echo Hiding Chat button
reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v TaskbarMn /t REG_DWORD /d 0 /f > nul

echo Setting Dark theme for system
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v "SystemUsesLightTheme" /t REG_DWORD /d 0 /f > nul

echo Enabling compact mode in Explorer
reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "UseCompactMode" /t REG_DWORD /d 1 /f > nul

IF "%darkMode%"=="true" (
	echo Setting dark theme for all apps
	reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v "AppsUseLightTheme" /t REG_DWORD /d 0 /f > nul
)

echo Disabling transparency effects
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v "EnableTransparency" /t REG_DWORD /d 0 /f > nul

echo Disabling post update "setting up pc" animation
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v EnableFirstLogonAnimation /t REG_DWORD /d 0 /f > nul
goto regend 

:regend
echo Enabling LSA and Memory Integrity
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v "EnableVirtualizationBasedSecurity" /t REG_DWORD /d 1 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v "RequirePlatformSecurityFeatures" /t REG_DWORD /d 1 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v "RequireCredentialGuard" /t REG_DWORD /d 1 /f


Set "VBSFILE=%~dp0\temp\%~n0.vbs
> "%VBSFILE%" (
    echo Wscript.Echo Opened_Folders
    echo Function Opened_Folders
    echo    Dim objShellApp,wFolder,Open_Folder,F
    echo    Set objShellApp = CreateObject("Shell.Application"^)
    echo    For Each wFolder In objShellApp.Windows
    echo        Open_Folder = wFolder.document.Folder.Self.Path
    echo        F = F ^& Open_Folder ^& vbcrlf
    echo    Next
    echo    Opened_Folders = F
    echo End Function
)
REM  Populate the array with existent and opened folders
SetLocal EnableDelayedExpansion
Set /a Count=0
for /f "delims=" %%a in ('Cscript //NoLogo "%VBSFILE%"') do (
    Set /a Count+=1
    Set "Folder[!Count!]=%%a"
)
Taskkill /f /IM "explorer.exe"  > nul
Echo Restarting explorer.exe
Timeout /T 1 /NoBreak>nul
Start Explorer.exe
rem Restore all folders before killing explorer process
for /L %%i in (1,1,%Count%) do Explorer "!Folder[%%i]!"

PowerShell.exe -ExecutionPolicy Bypass -File %~dp0autoinstall.ps1
::runs my powershell script from the same directory that auto installs and runs our remote support software


sfc /scannow
start  /min dism /online /cleanup-image /restorehealth
:loopupdate
if exist %temp%/hcsupdate.txt (
  echo updates complete, continuing with script
  del %temp%/hcsupdate.txt
  goto :end
) else (
  echo Updates are still downloading, waiting for them to finish before continuing...
  timeout /t 5 >nul
  goto :loopupdate
)



echo Enabling System Restore
powershell -command Enable-ComputerRestore -Drive "C:"
echo Creating restore point
wmic.exe /Namespace:\\root\default Path SystemRestore Call CreateRestorePoint "HCS", 100, 7 > nul
echo Restore Point created successfully

echo Uninstalling malwarebytes and rebooting

:end
echo Writing information to log file
echo Fin's setup script completed at: %date% %time% >> C:\HCSLog.txt
echo =================================================================================>> C:\HCSLog.txt
attrib +h C:\HCSLog.txt
taskkill /IM caf.exe /F > nul

echo Press any key to exit script, uninstall Malwarebytes and reboot
copy unin.bat %temp%
schtasks /create /tn "Uninstall Malwarebytes" /tr "%temp%\unin.bat" /sc ONSTARTUP /ru SYSTEM
pause > nul
shutdown /r /t 0
exit