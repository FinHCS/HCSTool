@echo off

set scriptDir=%cd%
title Fin's Final Script Version 0.1  [%~dp0]
setlocal
cd %~dp0

:: Check if script is already running as admin
net session >nul 2>&1
if %errorlevel% == 0 (
    goto main
)

:: Prompt user to run the script as administrator
echo Script needs to be run with administrative privileges.

echo Please select Yes when prompted by the User Account Control.

:: Launch a new instance of the script with elevated privileges
powershell -Command "Start-Process '%0' -Verb RunAs" && exit 2>$null 2>nul
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo UAC Prompt denied, press any key to exit
		pause >nul
	goto eof
)



:main
cd %scriptDir%
echo [%time%]Main Script started>> C:\HCSLog.txt
taskkill /IM caf.exe /f 2>nul > nul
rmdir /s /q %~dp0\scriptTemp 2>nul > nul
echo [%time%]Script was not opened with administrator permissions, launching UAC prompt>> C:\HCSLog.txt
echo Script is now running with administrative privileges.
netsh wlan add profile filename=%~dp0\myProfile.xml 2>nul > nul
cd %~dp0

rem Checks for an internet connection, and prompts user to connect ethernet if wifi isn't working/available
:loop
ping www.google.com -n 1 -w 1000 >nul
if %errorlevel% == 0 (
    echo Connected to HCS Internet
) else (
    echo Not Connected, please connect ethernet if WIFI is unavailable
    timeout /t 5 >nul
	netsh wlan add profile filename=%~dp0\myProfile.xml 
    goto loop
)

echo Enabling Network sharing
netsh advfirewall firewall set rule group="File and Printer Sharing" new enable=Yes > nul
netsh advfirewall firewall set rule group="network discovery" new enable=yes >nul



echo Adding HCS Server Credentials
cmdkey /add:hcsserver /user:hcsserver\Administrator /pass:A13nwar31 >nul


:sleep
rem This changes the power settings so the pc won't sleep while executing the script
rem using this method means this is only in effect while the process for this script is running, and will return to normal when its done
echo Downloading Prerequesites
if exist "Harpenden Computer Services\thumbs.db" del /s /q "Harpenden Computer Services\thumbs.db" 2>nul > nul
mkdir %~dp0\scriptTemp 2>nul > nul
attrib +h /s /d %~dp0\scriptTemp
cd %~dp0\scriptTemp
curl.exe https://www.zhornsoftware.co.uk/caffeine/caffeine.zip --output Caf.zip 2>nul > nul
echo Extracting..
tar -xf Caf.zip
ren caffeine64.exe caf.exe
cd ..
echo Setting pc to not sleep while script is executing, this will take a moment
start  /min "" "%~dp0\scriptTemp\caf.exe"
xcopy /s /i "\\hcsserver\3tb\hcs remote support - PC\Harpenden Computer Services" ".\scriptTemp\hcs" 2>nul > nul
rem Check if the build number is greater than or equal to 10.0.22000.0 as that is the difference between W10/W11
for /f "tokens=2 delims==" %%a in ('wmic os get BuildNumber /value') do set build=%%a
if %build% GEQ 22000 (
  echo [%time%] [INFO] System is running Windows 11>> C:\HCSLog.txt
  set /A winver=11
  echo Running on Windows 11, not running W10 specific registry tweaks

) else (
  echo [%time%] [INFO] System is running Windows 10>> C:\HCSLog.txt
  set /A winver=10
)


::========================================================================================================================================================
:MainMenu
CLS
color 07
cd %~dp0
mode 76, 30
echo:
echo:
echo:
echo:
echo:       ______________________________________________________________
echo:
echo:                 Activation Methods:
echo:
echo:             [1] New Windows Installation Setup
echo:             [2] Service
echo:             [3] Change Registry settings
echo:             __________________________________________________
echo:
echo:             [4] Install HCS Remote Support
echo:             [5] Windows Updates
echo:             [6] Install Chocolatey
echo:
echo:
echo:
echo:             __________________________________________________
echo:
echo:             [0] Exit and tidy up
echo:       ______________________________________________________________
echo:
echo:       Enter a menu option in the Keyboard [1,2,3,4,5,6] :
choice /C:1234560 /N
set _erl=%errorlevel%

if %_erl%==6 setlocal & call :instChocoOnly     & cls & endlocal & goto :MainMenu
if %_erl%==5 setlocal & call :winUpdate & cls & endlocal & goto :MainMenu
if %_erl%==4 setlocal & call :InstallRemote & cls & endlocal & goto :MainMenu
if %_erl%==3 setlocal & call :registryChanges     & cls & endlocal & goto :MainMenu
if %_erl%==2 setlocal & call :Service   & cls & endlocal & goto :MainMenu
if %_erl%==1 setlocal & call :NewSetup    & cls & endlocal & goto :MainMenu

if %_erl%==0 setlocal & call :exitAndCleanup     & cls & endlocal & goto :MainMenu

::========================================================================================================================================================

:NewSetup
cls
:promptAvast
Echo This script installs 
echo Google Chrome
echo VLC Media Player
echo 7-Zip
echo Zoom
echo Adobe Reader 
echo As well as a few command line utilities
echo ============================================================================
set /p AVAST="Do you also want to install Avast? (y/n)"
if /i "%AVAST%"=="y" (
    set avast=true
	echo [%time%]User chose to install Avast, skipping MWB prompt>> C:\HCSLog.txt
	goto promptGaming
) else if /i "%AVAST%"=="n" (
	echo [%time%]User chose not to install Avast>> C:\HCSLog.txt
	goto promptMalwarebytes

) else (
	cls
    echo Invalid input, please enter 'y' or 'n'.
	echo [%time%]User chose invalid option, retrying>> C:\HCSLog.txt
    goto promptAvast
)


:promptMalwarebytes

set /p malwarebytes="Do you want to install Malwarebytes instead? (y/n)"
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
echo Do you want to install Gaming software?
set /p gaming="This is Discord, Steam, EGS and Origin (y/n)"
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
	

) else (
    echo Invalid input, please enter 'y' or 'n'.
	echo [%time%]User chose invalid option, retrying>> C:\HCSLog.txt
    goto promptDarkMode
)

where choco > nul 2>&1
if %errorlevel% equ 0 (
	echo [%time%]Prior Chocolatey install detected, skipping installation>> C:\HCSLog.txt
    echo Chocolatey is installed, skipping installation
	break
	echo [%time%]Chocolatey is installed, skipping installation>> C:\HCSLog.txt

) else (
    echo Chocolatey is not installed, installing now
	echo [%time%]Chocolatey is not installed, installing now>> C:\HCSLog.txt
	goto instChoco
)


echo Installing software
choco feature enable -n=allowGlobalConfirmation > nul
echo [%time%]Enabled global conformation for Chocolatey >> C:\HCSLog.txt
::sets choco to not need conformation to install software
echo ============================================================================
echo When Chocolatey is installing software you can check for progress and errors                  by opening the minimised powershell window
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

IF "%avast%"=="true" (
	echo Installing Avast
	start /min /wait Powershell.exe choco install avastfreeantivirus -y --ignore-checksums > nul
	echo [%time%]Installed Avast>> C:\HCSLog.txt
)

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

setdefaultbrowser chrome
echo Setting default browser to Google Chrome
echo [%time%] Setting Default browser to Google Chrome >> C:\HCSLog.txt


PowerShell.exe -ExecutionPolicy Bypass -File %~dp0autoinstall.ps1
::runs my powershell script from the same directory that auto installs and runs our remote support software
echo Press any key to return to menu
echo ============================================================================
echo Please make sure to exit the script from the menu rather than closing the window
Taskkill /f /IM "caf.exe"  2>nul > nul
pause> nul
goto MainMenu

:Service
cls
call service.bat
echo Press any key to return to menu
echo ============================================================================
echo Please make sure to exit the script from the menu rather than closing the window
Taskkill /f /IM "caf.exe"  2>nul > nul
pause> nul
goto MainMenu

:InstallRemote
cls
PowerShell.exe -ExecutionPolicy Bypass -File %~dp0autoinstall.ps1
echo Press any key to return to menu
echo ============================================================================
echo Please make sure to exit the script from the menu rather than closing the window
Taskkill /f /IM "caf.exe"  2>nul > nul
pause> nul
goto MainMenu

:winUpdate
cls
PowerShell.exe -ExecutionPolicy Bypass -File %~dp0updates.ps1
echo Press any key to return to menu
echo ============================================================================
echo Please make sure to exit the script from the menu rather than closing the window
Taskkill /f /IM "caf.exe"  2>nul > nul
pause> nul
goto MainMenu

:instChocoOnly

cls
where choco > nul 2>&1
if %errorlevel% equ 0 (
	echo [%time%]Prior Chocolatey install detected, skipping installation>> C:\HCSLog.txt
    echo Chocolatey is installed, skipping installation
	break
	echo [%time%]Chocolatey is installed, skipping installation>> C:\HCSLog.txt

) else (
    echo Chocolatey is not installed, installing now
	echo [%time%]Chocolatey is not installed, installing now>> C:\HCSLog.txt
	goto instChoco
)
goto registryChanges

Taskkill /f /IM "caf.exe"  2>nul > nul
echo Press any key to return to menu
echo ============================================================================
echo Please make sure to exit the script from the menu rather than closing the window
pause> nul
goto MainMenu

:registryChanges

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
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" /v "SearchboxTaskbarMode" /t REG_DWORD /d 1 /f 2>nul > nul


echo Setting Dark theme for system
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v "SystemUsesLightTheme" /t REG_DWORD /d 0 /f 2>nul > nul
rem Check if the Windows Search key exists
reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows" /f "Windows Search" 2>nul > nul
if %errorlevel% == 0 (
  echo Windows Search key already exists
) else (
  echo Editing Registry to hide Search Bar
  reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows" /v "Windows Search" /t REG_DWORD /d 0 /f 2>nul > nul
)

rem Check if the AllowCortana value exists
reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "AllowCortana" 2>nul > nul
if %errorlevel% == 0 (
  echo AllowCortana value already exists
) else (
  echo Editing Registry to hide Cortana buttonvalue
  reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "AllowCortana" /t REG_DWORD /d 0 /f 2>nul > nul
)

echo Restarting Windows Search service...
net stop "Windows Search" 2>nul > nul
net start "Windows Search" 2>nul > nul

rem Change the registry value for the Explorer window that opens to "This PC"

reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v LaunchTo /t REG_DWORD /d 1 /f 2>nul > nul
echo Setting Windows Explorer to open to My PC by default
echo Disabling post update "setting up pc" animation
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v EnableFirstLogonAnimation /t REG_DWORD /d 0 /f 2>nul > nul

IF "%darkMode%"=="true" (
	echo Setting dark theme
	reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v "AppsUseLightTheme" /t REG_DWORD /d 0 /f 2>nul > nul
	reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v "SystemUsesLightTheme" /t REG_DWORD /d 0 /f 2>nul > nul

)

echo Disabling transparency effects
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v "EnableTransparency" /t REG_DWORD /d 0 /f 2>nul > nul


rem Set the news and interests feed to hidden
REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v ShellFeedsTaskbarViewMode /t REG_DWORD /d 2 /f 2>nul > nul

echo Taskbar search bar set to "Hide search bar"
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds" /v EnableFeeds /t REG_DWORD /d 0 /f 2>nul > nul
echo News and interests feed set to hidden

reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v LaunchTo /t REG_DWORD /d 1 /f 2>nul > nul
echo File explorer set to open to My PC
rem restarts explorer and reopens all open explorer windows
goto regend


:w11
echo Setting Taskbar Alignment to the left side
reg add "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v TaskbarAl /t REG_DWORD /d 0 /f 2>nul > nul

echo Hiding Widgets button
reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v TaskbarDa /t REG_DWORD /d 0 /f 2>nul > nul

echo Hiding Chat button
reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v TaskbarMn /t REG_DWORD /d 0 /f 2>nul > nul

echo Setting Dark theme for system
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v "SystemUsesLightTheme" /t REG_DWORD /d 0 /f 2>nul > nul

echo Enabling compact mode in Explorer
reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "UseCompactMode" /t REG_DWORD /d 1 /f 2>nul > nul

IF "%darkMode%"=="true" (
	echo Setting dark theme for all apps
	reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v "AppsUseLightTheme" /t REG_DWORD /d 0 /f 2>nul > nul
)

echo Disabling transparency effects
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v "EnableTransparency" /t REG_DWORD /d 0 /f 2>nul > nul

echo Disabling post update "setting up pc" animation
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v EnableFirstLogonAnimation /t REG_DWORD /d 0 /f 2>nul > nul
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

:exitAndCleanup
cls
echo Tidying up temporary files
Taskkill /f /IM "caf.exe"  2>nul > nul
rmdir /s /q %~dp0\scriptTemp
echo Allowing pc to sleep again
Taskkill /f /IM "caf.exe"  2>nul > nul
Echo Press any key to exit
pause> nul
exit

:instChoco
echo Installing Chocolatey


echo [%time%]Chocolatey not detected, installing now>> C:\HCSLog.txt
:: starts a minimised Powershell window as admin to install chocolatey to install packages later
start /min /wait Powershell.exe -executionpolicy remotesigned -command Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
echo [%time%]Chocolatey installed>> C:\HCSLog.txt


echo | set /p dummy="Refreshing environment variables from registry for cmd.exe. Please wait....."

goto mainChoc

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

:mainChoc
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
	break