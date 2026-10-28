@echo off
net session >nul 2>&1

if %errorLevel% neq 0 (
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)
@echo off
setlocal EnableExtensions
set "CURRENT_VERSION=2.2.0"
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
 "  $a=[version]$current; $b=[version]$remote;" ^
 "  if ($b -le $a) { exit 3 }" ^
 "  Invoke-WebRequest -UseBasicParsing -Uri $scriptUrl -OutFile $out -TimeoutSec 20;" ^
 "  if (!(Test-Path $out) -or (Get-Item $out).Length -lt 1000) { exit 4 }" ^
 "  $body=Get-Content -LiteralPath $out -Raw;" ^
 "  if ($body -notmatch '(?m)^set ""CURRENT_VERSION=\d+(\.\d+){1,3}""') { Remove-Item $out -Force -ErrorAction SilentlyContinue; exit 4 }" ^
 "  if ($body -notmatch '(?i)Isaeva Fix Tool') { Remove-Item $out -Force -ErrorAction SilentlyContinue; exit 4 }" ^
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

set "TARGET=%~f0"
set "BACKUP=%~f0.old"

(
    echo @echo off
    echo setlocal
    echo timeout /t 2 /nobreak ^>nul
    echo set "TARGET=%TARGET%"
    echo set "NEWFILE=%UPDATE_FILE%"
    echo set "BACKUP=%BACKUP%"
    echo if not exist "%%NEWFILE%%" exit /b 1
    echo if exist "%%BACKUP%%" del /f /q "%%BACKUP%%"
    echo move /y "%%TARGET%%" "%%BACKUP%%" ^>nul
    echo if errorlevel 1 exit /b 1
    echo move /y "%%NEWFILE%%" "%%TARGET%%" ^>nul
    echo if errorlevel 1 ^(
    echo   move /y "%%BACKUP%%" "%%TARGET%%" ^>nul
    echo   echo Update failed. Previous version restored.
    echo   pause
    echo   exit /b 1
    echo ^)
    echo start "" "%%TARGET%%"
    echo timeout /t 3 /nobreak ^>nul
    echo del /f /q "%%BACKUP%%" ^>nul 2^>^&1
    echo del /f /q "%%~f0" ^>nul 2^>^&1
) > "%TEMP%\IsaevaFixUpdater.cmd"

start "" /min "%TEMP%\IsaevaFixUpdater.cmd"
exit /b)

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
set /p CHOICE=Enter your choice (1-4): 
if "%CHOICE%"=="1" goto :ISAEVA_FIX
if "%CHOICE%"=="2" goto :LOGIN_INJECTION_FIX
if "%CHOICE%"=="3" goto :RUNTIME_FIX
if "%CHOICE%"=="4" exit /b
echo Invalid choice. Please try again.
timeout /t 2 >nul
goto :MAIN_MENU

:ISAEVA_FIX
cls
echo =====================================
echo   Isaeva Installer / Executor Fix
echo =====================================
echo.
echo This will:
echo   - Close Isaeva.exe if it is running.
echo   - Delete any existing Isaeva folder or Isaeva.exe on Desktop.
echo   - Download the latest Isaeva package.
echo   - Extract it to your Desktop.
echo   - Add the Isaeva folder to Windows Defender exclusions.
echo   - Launch Isaeva.exe.
echo.
set /p CONFIRM=Do you want to continue? (Y/N): 
if /I not "%CONFIRM%"=="Y" (
    echo Operation cancelled.
    timeout /t 3 /nobreak >nul
    goto :MAIN_MENU
)

echo.
echo [1/6] Closing Isaeva.exe if running...
taskkill /F /IM Isaeva.exe >nul 2>&1
timeout /t 2 /nobreak >nul

echo.
echo [2/6] Cleaning old Isaeva files from Desktop...
set "DESKTOP=%USERPROFILE%\Desktop"
if exist "%DESKTOP%\Isaeva" (
    rmdir /s /q "%DESKTOP%\Isaeva"
    echo Deleted Isaeva folder.
)
if exist "%DESKTOP%\Isaeva.exe" (
    del /F /Q "%DESKTOP%\Isaeva.exe"
    echo Deleted Isaeva.exe.
)

echo.
echo [3/6] Downloading Isaeva package...
set "ZIP_PATH=%TEMP%\Isaeva.zip"
powershell -ExecutionPolicy Bypass -Command "Invoke-WebRequest -Uri 'https://github.com/FixBats/FixIsaevabat/releases/download/Executor/Isaeva.zip' -OutFile '%ZIP_PATH%' -UseBasicParsing"
if not exist "%ZIP_PATH%" (
    echo [ERROR] Failed to download the package.
    timeout /t 3 /nobreak >nul
    goto :MAIN_MENU
)

echo.
echo [4/6] Extracting to Desktop...
powershell -ExecutionPolicy Bypass -Command "Expand-Archive -Path '%ZIP_PATH%' -DestinationPath '%DESKTOP%' -Force"
del /F /Q "%ZIP_PATH%" >nul 2>&1

set "ISAEVA_FOLDER=%DESKTOP%\Isaeva"
if not exist "%ISAEVA_FOLDER%" (
    echo [WARNING] Isaeva folder not found on Desktop. Skipping Defender exclusion.
    goto :SKIP_EXCLUSION
)

echo.
echo [5/6] Adding Isaeva folder to Windows Defender exclusions...
powershell -ExecutionPolicy Bypass -Command "Add-MpPreference -ExclusionPath '%ISAEVA_FOLDER%'" >nul 2>&1
if %errorLevel% equ 0 (
    echo Successfully added to exclusions.
) else (
    echo Failed to add exclusion. You may need to add it manually.
)

:SKIP_EXCLUSION
echo.
echo [6/6] Locating Isaeva.exe...
set "ISAEVA_EXE="
if exist "%ISAEVA_FOLDER%\Isaeva.exe" set "ISAEVA_EXE=%ISAEVA_FOLDER%\Isaeva.exe"
if not defined ISAEVA_EXE if exist "%DESKTOP%\Isaeva.exe" set "ISAEVA_EXE=%DESKTOP%\Isaeva.exe"

if not defined ISAEVA_EXE (
    echo [ERROR] Isaeva.exe was not found after extraction.
    echo Please check your Desktop and run it manually.
    timeout /t 3 /nobreak >nul
    goto :MAIN_MENU
)

echo.
echo Launching Isaeva.exe...
start "" "%ISAEVA_EXE%"

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
echo This will reset your network settings and sync your system time.
echo Commands to be executed:
echo   - ipconfig /flushdns
echo   - ipconfig /release
echo   - ipconfig /renew
echo   - netsh winsock reset
echo   - netsh int ip reset
echo   - w32tm /resync (time sync)
echo.
set /p CONFIRM=Do you want to continue? (Y/N): 
if /I not "%CONFIRM%"=="Y" (
    echo Operation cancelled.
    timeout /t 3 /nobreak >nul
    goto :MAIN_MENU
)
echo.
echo Flushing DNS cache...
ipconfig /flushdns
echo.
echo Releasing current IP address...
ipconfig /release
echo.
echo Renewing IP address...
ipconfig /renew
echo.
echo Resetting Winsock catalog...
netsh winsock reset
echo.
echo Resetting TCP/IP stack...
netsh int ip reset
echo.
echo Syncing system time...
net stop w32time >nul 2>&1
w32tm /unregister >nul 2>&1
w32tm /register >nul 2>&1
net start w32time >nul 2>&1
w32tm /config /manualpeerlist:"time.windows.com" /syncfromflags:manual /reliable:YES /update >nul 2>&1
w32tm /resync /force >nul 2>&1
echo.
echo Time sync completed.
echo.
echo All fixes applied. It is recommended to restart your PC.
echo.
timeout /t 3 /nobreak >nul
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
echo All installations will run silently.
echo.
set /p CONFIRM=Do you want to continue? (Y/N): 
if /I not "%CONFIRM%"=="Y" (
    echo Operation cancelled.
    timeout /t 3 /nobreak >nul
    goto :MAIN_MENU
)

set "TEMP_DIR=%TEMP%\Runtime_Fix"
if not exist "%TEMP_DIR%" mkdir "%TEMP_DIR%"

echo.
echo Downloading Visual C++ 2005 Redistributable (x86)...
set "URL=https://download.microsoft.com/download/8/B/4/8B42259F-5D70-43F4-AC2E-4B208FD8D66A/vcredist_x86.EXE"
set "FILE=%TEMP_DIR%\vc2005_x86.exe"
powershell -ExecutionPolicy Bypass -Command "Invoke-WebRequest -Uri '%URL%' -OutFile '%FILE%' -UseBasicParsing"
if exist "%FILE%" (
    echo Installing...
    start /wait "" "%FILE%" /q
) else (
    echo Failed to download. Skipping.
)

echo.
echo Downloading Visual C++ 2005 Redistributable (x64)...
set "URL=https://download.microsoft.com/download/8/B/4/8B42259F-5D70-43F4-AC2E-4B208FD8D66A/vcredist_x64.EXE"
set "FILE=%TEMP_DIR%\vc2005_x64.exe"
powershell -ExecutionPolicy Bypass -Command "Invoke-WebRequest -Uri '%URL%' -OutFile '%FILE%' -UseBasicParsing"
if exist "%FILE%" (
    echo Installing...
    start /wait "" "%FILE%" /q
) else (
    echo Failed to download. Skipping.
)

echo.
echo Downloading Visual C++ 2008 Redistributable (x86)...
set "URL=https://download.microsoft.com/download/5/D/8/5D8C65CB-C849-4025-8E95-C3966CAFD8AE/vcredist_x86.exe"
set "FILE=%TEMP_DIR%\vc2008_x86.exe"
powershell -ExecutionPolicy Bypass -Command "Invoke-WebRequest -Uri '%URL%' -OutFile '%FILE%' -UseBasicParsing"
if exist "%FILE%" (
    echo Installing...
    start /wait "" "%FILE%" /q /norestart
) else (
    echo Failed to download. Skipping.
)

echo.
echo Downloading Visual C++ 2008 Redistributable (x64)...
set "URL=https://download.microsoft.com/download/5/D/8/5D8C65CB-C849-4025-8E95-C3966CAFD8AE/vcredist_x64.exe"
set "FILE=%TEMP_DIR%\vc2008_x64.exe"
powershell -ExecutionPolicy Bypass -Command "Invoke-WebRequest -Uri '%URL%' -OutFile '%FILE%' -UseBasicParsing"
if exist "%FILE%" (
    echo Installing...
    start /wait "" "%FILE%" /q /norestart
) else (
    echo Failed to download. Skipping.
)

echo.
echo Downloading Visual C++ 2010 Redistributable (x86)...
set "URL=https://download.microsoft.com/download/1/6/5/165255E7-1014-4D0A-B094-B6A430A6BFFC/vcredist_x86.exe"
set "FILE=%TEMP_DIR%\vc2010_x86.exe"
powershell -ExecutionPolicy Bypass -Command "Invoke-WebRequest -Uri '%URL%' -OutFile '%FILE%' -UseBasicParsing"
if exist "%FILE%" (
    echo Installing...
    start /wait "" "%FILE%" /q /norestart
) else (
    echo Failed to download. Skipping.
)

echo.
echo Downloading Visual C++ 2010 Redistributable (x64)...
set "URL=https://download.microsoft.com/download/1/6/5/165255E7-1014-4D0A-B094-B6A430A6BFFC/vcredist_x64.exe"
set "FILE=%TEMP_DIR%\vc2010_x64.exe"
powershell -ExecutionPolicy Bypass -Command "Invoke-WebRequest -Uri '%URL%' -OutFile '%FILE%' -UseBasicParsing"
if exist "%FILE%" (
    echo Installing...
    start /wait "" "%FILE%" /q /norestart
) else (
    echo Failed to download. Skipping.
)

echo.
echo Downloading Visual C++ 2012 Redistributable (x86)...
set "URL=https://download.microsoft.com/download/1/6/B/16B06F60-3B20-4FF2-B699-5E9B7962F9AE/VSU_4/vcredist_x86.exe"
set "FILE=%TEMP_DIR%\vc2012_x86.exe"
powershell -ExecutionPolicy Bypass -Command "Invoke-WebRequest -Uri '%URL%' -OutFile '%FILE%' -UseBasicParsing"
if exist "%FILE%" (
    echo Installing...
    start /wait "" "%FILE%" /install /quiet /norestart
) else (
    echo Failed to download. Skipping.
)

echo.
echo Downloading Visual C++ 2012 Redistributable (x64)...
set "URL=https://download.microsoft.com/download/1/6/B/16B06F60-3B20-4FF2-B699-5E9B7962F9AE/VSU_4/vcredist_x64.exe"
set "FILE=%TEMP_DIR%\vc2012_x64.exe"
powershell -ExecutionPolicy Bypass -Command "Invoke-WebRequest -Uri '%URL%' -OutFile '%FILE%' -UseBasicParsing"
if exist "%FILE%" (
    echo Installing...
    start /wait "" "%FILE%" /install /quiet /norestart
) else (
    echo Failed to download. Skipping.
)

echo.
echo Downloading Visual C++ 2013 Redistributable (x86)...
set "URL=https://aka.ms/highcontrast/2013/vc_redist.x86.exe"
set "FILE=%TEMP_DIR%\vc2013_x86.exe"
powershell -ExecutionPolicy Bypass -Command "Invoke-WebRequest -Uri '%URL%' -OutFile '%FILE%' -UseBasicParsing"
if exist "%FILE%" (
    echo Installing...
    start /wait "" "%FILE%" /install /quiet /norestart
) else (
    echo Failed to download. Skipping.
)

echo.
echo Downloading Visual C++ 2013 Redistributable (x64)...
set "URL=https://aka.ms/highcontrast/2013/vc_redist.x64.exe"
set "FILE=%TEMP_DIR%\vc2013_x64.exe"
powershell -ExecutionPolicy Bypass -Command "Invoke-WebRequest -Uri '%URL%' -OutFile '%FILE%' -UseBasicParsing"
if exist "%FILE%" (
    echo Installing...
    start /wait "" "%FILE%" /install /quiet /norestart
) else (
    echo Failed to download. Skipping.
)

echo.
echo Downloading Visual C++ 2015-2022 Redistributable (x86)...
set "URL=https://aka.ms/vs/17/release/vc_redist.x86.exe"
set "FILE=%TEMP_DIR%\vc2015_2022_x86.exe"
powershell -ExecutionPolicy Bypass -Command "Invoke-WebRequest -Uri '%URL%' -OutFile '%FILE%' -UseBasicParsing"
if exist "%FILE%" (
    echo Installing...
    start /wait "" "%FILE%" /install /quiet /norestart
) else (
    echo Failed to download. Skipping.
)

echo.
echo Downloading Visual C++ 2015-2022 Redistributable (x64)...
set "URL=https://aka.ms/vs/17/release/vc_redist.x64.exe"
set "FILE=%TEMP_DIR%\vc2015_2022_x64.exe"
powershell -ExecutionPolicy Bypass -Command "Invoke-WebRequest -Uri '%URL%' -OutFile '%FILE%' -UseBasicParsing"
if exist "%FILE%" (
    echo Installing...
    start /wait "" "%FILE%" /install /quiet /norestart
) else (
    echo Failed to download. Skipping.
)

echo.
echo Enabling .NET Framework 3.5...
Dism /online /Enable-Feature /FeatureName:NetFx3 /All /NoRestart

echo.
echo Downloading .NET Framework 4.8...
set "URL=https://go.microsoft.com/fwlink/?linkid=2088631"
set "FILE=%TEMP_DIR%\dotnet48.exe"
powershell -ExecutionPolicy Bypass -Command "Invoke-WebRequest -Uri '%URL%' -OutFile '%FILE%' -UseBasicParsing"
if exist "%FILE%" (
    echo Installing...
    start /wait "" "%FILE%" /q /norestart
) else (
    echo Failed to download. Skipping.
)

echo.
echo Downloading DirectX End-User Runtime...
set "URL=https://download.microsoft.com/download/1/7/1/1718CCC4-6315-4D8E-9543-8E28A4E18C4C/dxwebsetup.exe"
set "FILE=%TEMP_DIR%\dxwebsetup.exe"
powershell -ExecutionPolicy Bypass -Command "Invoke-WebRequest -Uri '%URL%' -OutFile '%FILE%' -UseBasicParsing"
if exist "%FILE%" (
    echo Installing...
    start /wait "" "%FILE%" /Q
) else (
    echo Failed to download. Skipping.
)

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
