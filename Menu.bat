@echo off

set scriptDir=%cd%
title Fin's Final Script Version 0.1  [%~dp0]
setlocal
rmdir /s /q temp
cd %~dp0
mkdir temp
:: Check if script is already running as admin
net session >nul 2>&1
if %errorlevel% == 0 (
    goto main
)

:: Prompt user to run the script as administrator
echo Script needs to be run with administrative privileges.

echo Please select Yes when prompted by the User Account Control.

:: Launch a new instance of the script with elevated privileges
powershell -Command "Start-Process '%0' -Verb RunAs" && exit




:main
echo [%time%]Main Script started>> C:\HCSLog.txt
taskkill /IM caf.exe /f >nul
echo [%time%]Script was not opened with administrator permissions, launching UAC prompt>> C:\HCSLog.txt
echo Script is now running with administrative privileges.
netsh wlan add profile filename=%~dp0\myProfile.xml > nul
cd %~dp0

rem Checks for an internet connection, and prompts user to connect ethernet if wifi isn't working/available
:loop
ping www.google.com -n 1 -w 1000 >nul
if %errorlevel% == 0 (
    echo Connected to HCS Internet
) else (
    echo Not Connected, please connect ethernet if WIFI is unavailable
    timeout /t 5 >nul
    goto loop
)

echo Enabling Network sharing
netsh advfirewall firewall set rule group="File and Printer Sharing" new enable=Yes > nul
netsh advfirewall firewall set rule group="network discovery" new enable=yes >nul



echo Adding HCS Server Credentials
cmdkey /add:hcsserver /user:hcsserver\Administrator /pass:A13nwar31 >nul

cls

:sleep
rem This changes the power settings so the pc won't sleep while executing the script
rem using this method means this is only in effect while the process for this script is running, and will return to normal when its done
echo Downloading Prerequesites
cd /temp/
Invoke-WebRequest -Uri "https://zhornsoftware.co.uk/caffeine/caffeine.zip" -OutFile "Caf.zip"| Out-Null
echo Extracting..
powershell.exe -nologo -noprofile -command "& { Add-Type -A 'System.IO.Compression.FileSystem'; [IO.Compression.ZipFile]::ExtractToDirectory ('.\temp\caf.zip', '.\temp'); }"
echo Setting pc to not sleep while script is executing
start  /min "" %~dp0/temp/caf.exe
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
echo:                
echo:             __________________________________________________      
echo:                                                                     
echo:             [3] Install HCS Remote Support 
echo:             [4] Windows Updates
echo:             
echo:
echo:
echo:			  
echo:             __________________________________________________      
echo:             
echo:             [6] Exit and tidy up                       
echo:       ______________________________________________________________
echo:
echo:       Enter a menu option in the Keyboard [1,2,3,4,5,6] :
choice /C:123456 /N
set _erl=%errorlevel%

if %_erl%==6 setlocal & call :exitAndCleanup     & cls & endlocal & goto :MainMenu
REM if %_erl%==5 setlocal & call :_Check_Status_wmi_ext & cls & endlocal & goto :MainMenu
REM if %_erl%==4 setlocal & call :InstallRemote & cls & endlocal & goto :MainMenu
if %_erl%==3 setlocal & call :Service     & cls & endlocal & goto :MainMenu
if %_erl%==2 setlocal & call :InstallRemote   & cls & endlocal & goto :MainMenu
if %_erl%==1 setlocal & call :NewSetup    & cls & endlocal & goto :MainMenu

::========================================================================================================================================================

:NewSetup
cls
echo 
call newsetup.bat
Taskkill /f /IM "caf.exe"  > nul
goto MainMenu

:Service
cls
call service.bat
echo Press any key to return to menu
echo ============================================================================  
echo Please make sure to exit the script from the menu rather than closing the window
Taskkill /f /IM "caf.exe"  > nul
pause> nul
goto MainMenu

:InstallRemote
cls
PowerShell.exe -ExecutionPolicy Bypass -File %~dp0autoinstall.ps1
echo Press any key to return to menu
echo ============================================================================  
echo Please make sure to exit the script from the menu rather than closing the window
Taskkill /f /IM "caf.exe"  > nul
pause> nul
goto MainMenu

:winUpdate
cls
PowerShell.exe -ExecutionPolicy Bypass -File %~dp0updates.ps1
echo Press any key to return to menu
echo ============================================================================  
echo Please make sure to exit the script from the menu rather than closing the window
Taskkill /f /IM "caf.exe"  > nul
pause> nul
goto MainMenu

:exitAndCleanup
echo Tidying up temporary files
rmdir /s /q temp
echo Allowing pc to sleep again
Taskkill /f /IM "caf.exe"  > nul
pause> nul
