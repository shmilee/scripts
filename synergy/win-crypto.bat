xcopy "%ProgramFiles%\Synergy/Plugins/ns.dll" "%LOCALAPPDATA%\Synergy\Plugins\" /F
md %LOCALAPPDATA%\Synergy\SSL\Fingerprints
set /p FFPP=add the server FingerPrint: 
echo %FFPP%>%LOCALAPPDATA%\Synergy\SSL\Fingerprints\TrustedServers.txt
@echo Run Command:
@echo "%ProgramFiles%\Synergy\synergyc.exe -n arch-T450 --enable-crypto <Server IP>"
pause
