:: CHANGELOG 1.1
:: Changed all the chocolatey software installs to be in minimised
:: windows, so if something is hanging the user can see
@echo off
:promptAvast
set /p AVAST="Do you want to install Avast? (y/n)"
if /i "%AVAST%"=="y" (
    set avast=true
	echo [%time%]User chose to install Avast, skipping MWB prompt>> C:\HCSLog.txt
	goto promptGaming
) else if /i "%AVAST%"=="n" (
	echo [%time%]User chose not to install Avast>> C:\HCSLog.txt
	goto promptMalwarebytes

) else (
    echo Invalid input, please enter 'y' or 'n'.
	echo [%time%]User chose invalid option, retrying>> C:\HCSLog.txt
    goto promptAvast
)


:promptMalwarebytes
set /p malwarebytes="Do you want to install Malwarebytes? (y/n)"
if /i "%malwarebytes%"=="y" (
    set malwarebytes=true
	goto promptGaming
	echo [%time%]User chose to install Malwarebytes >> C:\HCSLog.txt
) else if /i "%malwarebytes%"=="n" (
	goto promptGaming

) else (
    echo Invalid input, please enter 'y' or 'n'.
	echo [%time%]User chose invalid option, retrying>> C:\HCSLog.txt
    goto promptMalwarebytes
)


:promptGaming
set /p gaming="Do you want to install Gaming software? (y/n)"
if /i "%gaming%"=="y" (
	echo [%time%]User chose to install gaming software>> C:\HCSLog.txt
    set gaming=true
	goto promptDarkMode
) else if /i "%gaming%"=="n" (
	echo [%time%]User chose not to install gaming software>> C:\HCSLog.txt
	goto promptDarkMode

) else (
    echo Invalid input, please enter 'y' or 'n'.
	echo [%time%]User chose invalid option, retrying>> C:\HCSLog.txt
    goto promptGaming
)

:promptDarkMode
set /p darkMode="Do you want to enable Dark Mode for applications? (y/n)"
if /i "%darkMode%"=="y" (
	echo [%time%]User chose to enable Dark Mode>> C:\HCSLog.txt
    set darkMode=true
) else if /i "%darkMode%"=="n" (
	echo [%time%]User chose not to enable Dark Mode>> C:\HCSLog.txt
	goto setup

) else (
    echo Invalid input, please enter 'y' or 'n'.
	echo [%time%]User chose invalid option, retrying>> C:\HCSLog.txt
    goto promptDarkMode
)



:setup

REM echo Running activation command...
REM start /min /wait Powershell.exe -executionpolicy remotesigned -command & ([ScriptBlock]::Create((irm https://massgrave.dev/get))) /HWID
REM echo [%time%]Ran Windows Activation Script>> C:\HCSLog.txt



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
echo ============================================================================
echo When Chocolatey is installing software you can check for progress and errors by opening the minimised powershell window
echo ============================================================================
echo Installing utilities and prerequesites
start /min /wait Powershell.exe -command choco install gsudo PSWindowsUpdate setdefaultbrowser -y --ignore-checksums > nul

echo [%time%]Installed PSWindowsUpdate, gsudo and setdefaultbrowser>> C:\HCSLog.txt

:software
echo Installing Google Chrome
start /min /wait Powershell.exe choco install googlechrome -y --ignore-checksums > nul
echo [%time%]Installed Google Chrome >> C:\HCSLog.txt
echo Installing VLC Media Player
start /min /wait Powershell.exe choco install vlc -y --ignore-checksums > nul
echo [%time%]Installed VLC Media Player >> C:\HCSLog.txt
echo Installing 7-Zip
start /min /wait Powershell.exe choco install 7zip -y --ignore-checksums > nul
echo [%time%]Installed 7-Zip>> C:\HCSLog.txt
echo Installing Zoom
start /min /wait Powershell.exe choco install zoom -y --ignore-checksums > nul
echo [%time%]Installed Zoom>> C:\HCSLog.txt
echo Installing Adobe Reader
start /min /wait Powershell.exe choco install adobereader -params '"/DesktopIcon /UpdateMode:3"' -y --ignore-checksums > nul
echo [%time%]Installed Adobe Reader>> C:\HCSLog.txt

:: adobe acrobat needs paramaters to create a desktop icon and turn on auto update

cd %~dp0


::the script asks the user earlier if they want to install Avast. This is our standard antivirus but often customers already have one,
::so by asking beforehand it saves us from having to uninstall it after running this script
IF "%avast%"=="true" (
	echo Installing Avast
	start /min /wait Powershell.exe choco install avastfreeantivirus -y --ignore-checksums > nul
	echo [%time%]Installed Avast>> C:\HCSLog.txt
)

REM IF "%office2013%"=="true" (
	REM echo Installing Office 2013
	REM choco install officeproplus2013 -y --ignore-checksums > nul
	REM echo [%time%]Installed Office 2013>> C:\HCSLog.txt
REM )

IF "%malwarebytes%"=="true" (
	echo Installing Malwarebytes
    start /min /wait Powershell.exe choco install malwarebytes -y --ignore-checksums> nul
	echo [%time%]Installed Malwarebytes>> C:\HCSLog.txt
)
IF "%gaming%"=="true" (
	echo Installing gaming software
	echo Installing Discord
    start /min /wait Powershell.exe choco install discord -y --ignore-checksums> nul
	echo [%time%]Installed Discord >> C:\HCSLog.txt
	echo Installing Steam
	start /min /wait Powershell.exe choco install steam -y --ignore-checksums> nul
	echo [%time%]Installed Steam >> C:\HCSLog.txt
	echo Installing Epic Games
	start /min /wait Powershell.exe choco install epicgameslauncher -y --ignore-checksums> nul
	echo [%time%]Installed Epic Games Launcher >> C:\HCSLog.txt
	echo Installing Origin
	start /min /wait Powershell.exe choco install origin -y --ignore-checksums> nul
	echo [%time%]Installed Origin >> C:\HCSLog.txt
)

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
	reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v "SystemUsesLightTheme" /t REG_DWORD /d 0 /f > nul

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



:end
echo Writing information to log file
echo User chose to install: >> C:\HCSLog.txt
echo Avast = %avast% >> C:\HCSLog.txt
echo Malwarebytes = %malwarebytes% >> C:\HCSLog.txt
echo Gaming software = %gaming% >> C:\HCSLog.txt
echo =================================================================================>> C:\HCSLog.txt
echo [%time%]Fin's setup script completed at: %date% %time% >> C:\HCSLog.txt
attrib +h C:\HCSLog.txt
echo Press any key to exit script and return to menu
pause > nul
