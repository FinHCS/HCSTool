@echo off
cd %temp%
Powershell.exe Invoke-WebRequest -Uri "https://downloads.malwarebytes.com/file/mbstcmd" -OutFile "mwbcmd.exe"
%~dp0/mwbcmd.exe /y /cleanup

del "%temp%\unin.lnk"
schtasks /delete /tn "Uninstall Malwarebytes" /f
pause