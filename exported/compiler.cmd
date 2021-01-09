@echo off
setlocal enabledelayedexpansion
for /f "tokens=2*" %%a in ('reg.exe query "HKEY_CURRENT_USER\Software\Valve\Steam" /v "SteamPath" ^| find /i "SteamPath"') do set STEAM_PATH=%%b
echo STEAM_PATH: %STEAM_PATH%
echo.
echo FOLDER: %1
echo.
echo.
cd %STEAM_PATH%\steamapps\common\Don't Starve Mod Tools\mod_tools\
echo Compiling:
for /R %1 %%f in (*.scml) do @IF EXIST %%f @scml.exe "%%f" %1
echo.
pause
@OP