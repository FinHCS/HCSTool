@echo off

mkdir temp
echo Downloading Prerequesites
cd temp
pause
Powershell.exe Invoke-WebRequest -Uri "https://zhornsoftware.co.uk/caffeine/caffeine.zip" -OutFile "Caf.zip"
echo Extracting..
Powershell.exe Expand-Archive -Path $PWD/*.zip -DestinationPath $PWD -Force
ren caffeine64.exe caf.exe
echo Setting pc to not sleep while script is executing
start  /min "" %~dp0/temp/caf.exe
pause