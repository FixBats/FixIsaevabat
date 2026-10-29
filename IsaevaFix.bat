@echo off
setlocal EnableExtensions EnableDelayedExpansion

:: Relaunch as administrator in a persistent CMD window
net session >nul 2>&1
if errorlevel 1 (
    set "BAT_SCRIPT=%~f0"
    powershell -NoProfile -ExecutionPolicy Bypass -Command "$cmd=$env:ComSpec; $bat=$env:BAT_SCRIPT; $q=[char]34; Start-Process -FilePath $cmd -Verb RunAs -ArgumentList ('/k call ' + $q + $bat + $q)"
    exit /b
)

set "CURRENT_VERSION=2.4.2"
set "VERSION_URL=https://raw.githubusercontent.com/FixBats/FixIsaevabat/main/version.txt"
set "SCRIPT_URL=https://raw.githubusercontent.com/FixBats/FixIsaevabat/main/IsaevaFix.bat"
set "UPDATE_FILE=%TEMP%\IsaevaFix-update-%RANDOM%.bat"
set "UPDATE_HELPER=%TEMP%\IsaevaFix-update-%RANDOM%.cmd"

title Isaeva Fix Tool
color 5
echo Checking for Isaeva Fix Tool updates...

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
 "$ErrorActionPreference='Stop';" ^
 "$current='%CURRENT_VERSION%'; $versionUrl='%VERSION_URL%'; $scriptUrl='%SCRIPT_URL%'; $out='%UPDATE_FILE%';" ^
 "try {" ^
 "  $remote=(Invoke-WebRequest -UseBasicParsing -Uri $versionUrl -TimeoutSec 8).Content.Trim();" ^
 "  if ($remote -notmatch '^\d+(\.\d+){1,3}$') { exit 2 }" ^
 "  if ([version]$remote -le [version]$current) { exit 3 }" ^
 "  Invoke-WebRequest -UseBasicParsing -Uri $scriptUrl -OutFile $out -TimeoutSec 20;" ^
 "  if (!(Test-Path -LiteralPath $out) -or (Get-Item -LiteralPath $out).Length -lt 1000) { exit 4 }" ^
 "  $body=Get-Content -LiteralPath $out -Raw;" ^
 "  if ($body -notmatch 'CURRENT_VERSION=\d+(\.\d+){1,3}' -or $body -notmatch '(?i)Isaeva Fix Tool') { Remove-Item -LiteralPath $out -Force -ErrorAction SilentlyContinue; exit 4 }" ^
 "  exit 0" ^
 "} catch { exit 1 }" >nul 2>&1

if "%errorlevel%"=="0" goto :APPLY_UPDATE
if "%errorlevel%"=="1" echo [Updater] GitHub unavailable. Continuing with current version.
if "%errorlevel%"=="2" echo [Updater] version.txt has an invalid version format.
if "%errorlevel%"=="3" echo Isaeva Fix Tool is up to date.
if "%errorlevel%"=="4" echo [Updater] Download validation failed. Continuing with current version.
timeout /t 1 /nobreak >nul
goto :MAIN_MENU

:APPLY_UPDATE
echo New version found. Applying update...
(
    echo @echo off
    echo timeout /t 2 /nobreak ^>nul
    echo copy /y "%UPDATE_FILE%" "%~f0" ^>nul
    echo if errorlevel 1 ^(
    echo   echo Update failed. The current version was kept.
    echo   pause
    echo   exit /b 1
    echo ^)
    echo del /f /q "%UPDATE_FILE%" ^>nul 2^>^&1
    echo start "" "%~f0"
    echo del /f /q "%%~f0" ^>nul 2^>^&1
) > "%UPDATE_HELPER%"
start "" /min "%UPDATE_HELPER%"
exit /b

:MAIN_MENU
cls
echo =====================================
echo          Isaeva Fix Tool
echo =====================================
echo.
echo Select the fix you want to apply:
echo.
echo   1. Isaeva Installer / Executor Fix
echo   2. Login / Injection Fix
echo   3. Install All Runtimes / Dependencies
echo   4. Exit
echo.
set "CHOICE="
set /p "CHOICE=Enter your choice (1-4): "
if "%CHOICE%"=="1" goto :ISAEVA_FIX
if "%CHOICE%"=="2" goto :LOGIN_INJECTION_FIX
if "%CHOICE%"=="3" goto :RUNTIME_FIX
if "%CHOICE%"=="4" exit
echo Invalid choice. Please try again.
timeout /t 2 /nobreak >nul
goto :MAIN_MENU

:ISAEVA_FIX
cls
echo =====================================
echo   Isaeva Installer / Executor Fix
echo =====================================
echo.
echo This will:
echo   - Close Isaeva.exe if it is running.
echo   - Clean old Isaeva folders and files from Desktop.
echo   - Download and extract the Isaeva package directly to Desktop.
echo   - Locate and launch Isaeva.exe.
echo.
set "CONFIRM="
set /p "CONFIRM=Do you want to continue? (Y/N): "
if /I not "%CONFIRM%"=="Y" (
    echo Operation cancelled.
    timeout /t 2 /nobreak >nul
    goto :MAIN_MENU
)

echo.
echo [1/6] Closing Isaeva.exe if running...
taskkill /F /IM Isaeva.exe >nul 2>&1
timeout /t 1 /nobreak >nul

for /f "usebackq delims=" %%D in (`powershell -NoProfile -Command "[Environment]::GetFolderPath('Desktop')"`) do set "DESKTOP=%%D"
if not defined DESKTOP set "DESKTOP=%USERPROFILE%\Desktop"

echo.
echo [2/6] Cleaning old Isaeva files from Desktop...
rem Match Isaeva, Isaeva 1, Isaeva(1), Isaeva(1)(2), etc.
powershell -NoProfile -ExecutionPolicy Bypass -Command "$d=$env:DESKTOP; $items=@(Get-ChildItem -LiteralPath $d -Force -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -match '^Isaeva(?:\s*\(\d+\)|\s*\d+)*$' }); foreach ($item in $items) { Write-Host ('Deleting folder: ' + $item.FullName); Remove-Item -LiteralPath $item.FullName -Recurse -Force -ErrorAction SilentlyContinue }"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$d=$env:DESKTOP; $items=@(Get-ChildItem -LiteralPath $d -Force -File -ErrorAction SilentlyContinue | Where-Object { $_.Extension -ieq '.exe' -and $_.BaseName -match '^Isaeva(?:\s*\(\d+\)|\s*\d+)*$' }); foreach ($item in $items) { Write-Host ('Deleting file: ' + $item.FullName); Remove-Item -LiteralPath $item.FullName -Force -ErrorAction SilentlyContinue }"

echo.
echo [3/6] Downloading Isaeva package...
set "ZIP_PATH=%TEMP%\Isaeva.zip"
if exist "%ZIP_PATH%" del /f /q "%ZIP_PATH%" >nul 2>&1
powershell -NoProfile -ExecutionPolicy Bypass -Command "try { $ErrorActionPreference='Stop'; Invoke-WebRequest -Uri 'https://github.com/FixBats/FixIsaevabat/releases/download/Executor/Isaeva.zip' -OutFile $env:ZIP_PATH -UseBasicParsing; exit 0 } catch { Write-Host $_; exit 1 }"
if errorlevel 1 (
    echo [ERROR] Failed to download the package.
    del /f /q "%ZIP_PATH%" >nul 2>&1
    pause
    goto :MAIN_MENU
)
if not exist "%ZIP_PATH%" (
    echo [ERROR] Downloaded ZIP was not found.
    pause
    goto :MAIN_MENU
)

echo.
echo [4/6] Extracting package directly to Desktop...
powershell -NoProfile -ExecutionPolicy Bypass -Command "try { $ErrorActionPreference='Stop'; Expand-Archive -LiteralPath $env:ZIP_PATH -DestinationPath $env:DESKTOP -Force; exit 0 } catch { Write-Host $_; exit 1 }"
if errorlevel 1 (
    echo [ERROR] Failed to extract the ZIP.
    del /f /q "%ZIP_PATH%" >nul 2>&1
    pause
    goto :MAIN_MENU
)
del /f /q "%ZIP_PATH%" >nul 2>&1

echo.
echo [5/6] Locating Isaeva.exe in all extracted folders...
echo Searching for the exact filename Isaeva.exe...

powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; try { $desktop=$env:DESKTOP; $exe=Get-ChildItem -LiteralPath $desktop -Filter 'Isaeva.exe' -File -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1; if ($null -eq $exe) { Write-Host '[ERROR] Isaeva.exe was not found.'; exit 2 }; Write-Host ('Found executable: ' + $exe.FullName); Write-Host 'Launching from its actual folder...'; Start-Process -FilePath $exe.FullName -WorkingDirectory $exe.DirectoryName -ErrorAction Stop; exit 0 } catch { Write-Host ('[ERROR] ' + $_.Exception.Message); exit 1 }"
set "LAUNCH_RESULT=%errorlevel%"

if not "%LAUNCH_RESULT%"=="0" (
    echo.
    echo Could not find or launch Isaeva.exe. Error code: %LAUNCH_RESULT%
    echo The tool will return to the main menu.
    pause
    goto :MAIN_MENU
)

echo.
echo [6/6] Launch command sent.
echo.
echo =====================================
echo       ISAEVA FIX COMPLETED
echo =====================================
echo.
timeout /t 3 /nobreak >nul
goto :MAIN_MENU

:LOGIN_INJECTION_FIX
cls
echo =====================================
echo       Login / Injection Fix
echo =====================================
echo.
echo This will:
echo   - Close Roblox and Roblox Studio if running.
echo   - Delete local Roblox client files in "%LOCALAPPDATA%\Roblox".
echo   - Clear Roblox temporary files.
echo   - Flush DNS and reset network settings.
echo   - Sync the Windows system time.
echo.
echo NOTE: Roblox may need to reinstall its client files next launch.
echo Local Roblox app settings may be removed; browser cookies are not targeted.
echo.
set "CONFIRM="
set /p "CONFIRM=Do you want to continue? (Y/N): "
if /I not "%CONFIRM%"=="Y" (
    echo Operation cancelled.
    timeout /t 2 /nobreak >nul
    goto :MAIN_MENU
)

echo.
echo [1/5] Closing Roblox processes...
taskkill /F /IM RobloxPlayerBeta.exe >nul 2>&1
taskkill /F /IM RobloxStudioBeta.exe >nul 2>&1
timeout /t 1 /nobreak >nul

echo.
echo [2/5] Removing local Roblox folder...
set "ROBLOX_DIR=%LOCALAPPDATA%\Roblox"
if exist "%ROBLOX_DIR%" (
    rmdir /s /q "%ROBLOX_DIR%" >nul 2>&1
    if exist "%ROBLOX_DIR%" (
        echo [WARNING] Some files could not be deleted. Close remaining Roblox processes and retry.
    ) else (
        echo Local Roblox folder deleted.
    )
) else (
    echo Local Roblox folder not found. Skipping.
)

echo.
echo [3/5] Cleaning Roblox temporary files...
set "ROBLOX_TEMP=%LOCALAPPDATA%\Temp\Roblox"
if exist "%ROBLOX_TEMP%" (
    rmdir /s /q "%ROBLOX_TEMP%" >nul 2>&1
    if exist "%ROBLOX_TEMP%" (
        echo [WARNING] Some Roblox temporary files could not be deleted.
    ) else (
        echo Roblox temporary files cleaned.
    )
) else (
    echo Roblox temp folder not found. Skipping.
)

echo.
echo [4/5] Flushing DNS cache...
ipconfig /flushdns

echo.
echo [5/5] Resetting network settings and syncing time...
ipconfig /release
ipconfig /renew
netsh winsock reset
netsh int ip reset
net stop w32time >nul 2>&1
w32tm /unregister >nul 2>&1
w32tm /register >nul 2>&1
net start w32time >nul 2>&1
w32tm /config /manualpeerlist:"time.windows.com" /syncfromflags:manual /reliable:YES /update >nul 2>&1
w32tm /resync /force >nul 2>&1
echo.
echo Login / Injection Fix completed.
echo Local Roblox client files were removed; browser cookies were not targeted.
echo A PC restart may be needed for network changes to fully apply.
echo.
pause
goto :MAIN_MENU

:RUNTIME_FIX
cls
echo =====================================
echo   Install Runtimes / Dependencies
echo =====================================
echo.
echo This will download and install:
echo   - Visual C++ 2005-2022 Redistributables (x86 & x64)
echo   - Microsoft .NET Framework 3.5 and 4.8
echo   - DirectX End-User Runtime
echo.
echo Installers will run silently where supported.
echo.
set "CONFIRM="
set /p "CONFIRM=Do you want to continue? (Y/N): "
if /I not "%CONFIRM%"=="Y" (
    echo Operation cancelled.
    timeout /t 2 /nobreak >nul
    goto :MAIN_MENU
)
set "TEMP_DIR=%TEMP%\Runtime_Fix"
if not exist "%TEMP_DIR%" mkdir "%TEMP_DIR%"

call :INSTALL_PACKAGE "https://download.microsoft.com/download/8/B/4/8B42259F-5D70-43F4-AC2E-4B208FD8D66A/vcredist_x86.EXE" "vc2005_x86.exe" "/q"
call :INSTALL_PACKAGE "https://download.microsoft.com/download/8/B/4/8B42259F-5D70-43F4-AC2E-4B208FD8D66A/vcredist_x64.EXE" "vc2005_x64.exe" "/q"
call :INSTALL_PACKAGE "https://download.microsoft.com/download/5/D/8/5D8C65CB-C849-4025-8E95-C3966CAFD8AE/vcredist_x86.exe" "vc2008_x86.exe" "/q /norestart"
call :INSTALL_PACKAGE "https://download.microsoft.com/download/5/D/8/5D8C65CB-C849-4025-8E95-C3966CAFD8AE/vcredist_x64.exe" "vc2008_x64.exe" "/q /norestart"
call :INSTALL_PACKAGE "https://download.microsoft.com/download/1/6/5/165255E7-1014-4D0A-B094-B6A430A6BFFC/vcredist_x86.exe" "vc2010_x86.exe" "/q /norestart"
call :INSTALL_PACKAGE "https://download.microsoft.com/download/1/6/5/165255E7-1014-4D0A-B094-B6A430A6BFFC/vcredist_x64.exe" "vc2010_x64.exe" "/q /norestart"
call :INSTALL_PACKAGE "https://download.microsoft.com/download/1/6/B/16B06F60-3B20-4FF2-B699-5E9B7962F9AE/VSU_4/vcredist_x86.exe" "vc2012_x86.exe" "/install /quiet /norestart"
call :INSTALL_PACKAGE "https://download.microsoft.com/download/1/6/B/16B06F60-3B20-4FF2-B699-5E9B7962F9AE/VSU_4/vcredist_x64.exe" "vc2012_x64.exe" "/install /quiet /norestart"
call :INSTALL_PACKAGE "https://aka.ms/highcontrast/2013/vc_redist.x86.exe" "vc2013_x86.exe" "/install /quiet /norestart"
call :INSTALL_PACKAGE "https://aka.ms/highcontrast/2013/vc_redist.x64.exe" "vc2013_x64.exe" "/install /quiet /norestart"
call :INSTALL_PACKAGE "https://aka.ms/vs/17/release/vc_redist.x86.exe" "vc2015_2022_x86.exe" "/install /quiet /norestart"
call :INSTALL_PACKAGE "https://aka.ms/vs/17/release/vc_redist.x64.exe" "vc2015_2022_x64.exe" "/install /quiet /norestart"

echo.
echo Enabling .NET Framework 3.5...
Dism /online /Enable-Feature /FeatureName:NetFx3 /All /NoRestart

call :INSTALL_PACKAGE "https://go.microsoft.com/fwlink/?linkid=2088631" "dotnet48.exe" "/q /norestart"
call :INSTALL_PACKAGE "https://download.microsoft.com/download/1/7/1/1718CCC4-6315-4D8E-9543-8E28A4E18C4C/dxwebsetup.exe" "dxwebsetup.exe" "/Q"

echo.
echo Cleaning up temporary files...
rmdir /s /q "%TEMP_DIR%" >nul 2>&1
echo.
echo =====================================
echo   RUNTIME INSTALLATION COMPLETED
echo =====================================
echo.
timeout /t 3 /nobreak >nul
goto :MAIN_MENU

:INSTALL_PACKAGE
set "PKG_URL=%~1"
set "PKG_NAME=%~2"
set "PKG_ARGS=%~3"
set "PKG_FILE=%TEMP_DIR%\%PKG_NAME%"
echo.
echo Downloading %PKG_NAME%...
if exist "%PKG_FILE%" del /f /q "%PKG_FILE%" >nul 2>&1
powershell -NoProfile -ExecutionPolicy Bypass -Command "try { $ErrorActionPreference='Stop'; Invoke-WebRequest -UseBasicParsing -Uri '%PKG_URL%' -OutFile '%PKG_FILE%' -TimeoutSec 60; exit 0 } catch { exit 1 }"
if not exist "%PKG_FILE%" (
    echo Download failed. Skipping %PKG_NAME%.
    exit /b 0
)
echo Installing %PKG_NAME%...
start /wait "" "%PKG_FILE%" %PKG_ARGS%
exit /b 0
