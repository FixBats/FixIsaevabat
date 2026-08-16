@echo off
net session >nul 2>&1
if %errorLevel% neq 0 (
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)
title Isaeva Fix Tool
color 5

set "CURRENT_VERSION=1.1"
set "VERSION_URL=https://raw.githubusercontent.com/FixBats/FixIsaevabat/main/version.txt"
set "BAT_URL=https://raw.githubusercontent.com/FixBats/FixIsaevabat/main/IsaevaFix.bat"
set "ZIP_URL=https://github.com/FixBats/FixIsaevabat/releases/download/Executor/Isaeva.zip"
set "UPDATE_TEMP=%TEMP%\IsaevaFix_new.bat"
set "UPDATER_TEMP=%TEMP%\IsaevaUpdater.bat"

if "%1"=="--updated" goto :MAIN_MENU

echo =====================================
echo          Isaeva Fix Tool v%CURRENT_VERSION%
echo =====================================
echo.
echo Checking for updates...
powershell -ExecutionPolicy Bypass -Command "try { $v = (Invoke-WebRequest -Uri '%VERSION_URL%' -TimeoutSec 5 -UseBasicParsing).Content.Trim(); Set-Content -Path '%TEMP%\iv.txt' -Value $v -NoNewline } catch { }" >nul 2>&1
if not exist "%TEMP%\iv.txt" (
    echo [Update] Could not reach update server. Continuing with current version.
    echo.
    goto :MAIN_MENU
)
set /p LATEST_VERSION=<"%TEMP%\iv.txt"
del "%TEMP%\iv.txt" >nul 2>&1
if "%LATEST_VERSION%"=="%CURRENT_VERSION%" (
    echo [Update] Already up to date ^(v%CURRENT_VERSION%^).
    echo.
    goto :MAIN_MENU
)
echo [Update] New version found: v%LATEST_VERSION% ^(current: v%CURRENT_VERSION%^)
echo Downloading update...
powershell -ExecutionPolicy Bypass -Command "try { Invoke-WebRequest -Uri '%BAT_URL%' -OutFile '%UPDATE_TEMP%' -UseBasicParsing } catch { }" >nul 2>&1
if not exist "%UPDATE_TEMP%" (
    echo [Update] Download failed. Continuing with current version.
    echo.
    goto :MAIN_MENU
)
rem Verify that the downloaded file is a batch file by checking for :MAIN_MENU
findstr /C:":MAIN_MENU" "%UPDATE_TEMP%" >nul 2>&1
if %errorLevel% neq 0 (
    echo [Update] Downloaded file is invalid. Continuing with current version.
    del /F /Q "%UPDATE_TEMP%" >nul 2>&1
    echo.
    goto :MAIN_MENU
)
set "SELF=%~f0"
(
    echo @echo off
    echo ping -n 3 127.0.0.1 ^>nul
    echo copy /Y "%UPDATE_TEMP%" "%SELF%" ^>nul
    echo del /F /Q "%UPDATE_TEMP%"
    echo del /F /Q "%TEMP%\iv.txt" 2^>nul
    echo start "" "%SELF%" --updated
    echo del /F /Q "%UPDATER_TEMP%"
) > "%UPDATER_TEMP%"
echo [Update] Update downloaded. Restarting with new version...
start "" "%UPDATER_TEMP%"
exit /b

:MAIN_MENU
cls
echo =====================================
echo          Isaeva Fix Tool v%CURRENT_VERSION%
echo =====================================
echo.
echo Select the fix you want to apply:
echo.
echo   1. Isaeva Installer / Executor Fix
echo   2. Login / Injection Fix
echo   3. Exit
echo.
set /p CHOICE=Enter your choice (1-3): 
if "%CHOICE%"=="1" goto :ISAEVA_FIX
if "%CHOICE%"=="2" goto :LOGIN_INJECTION_FIX
if "%CHOICE%"=="3" exit /b
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
    pause
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
powershell -ExecutionPolicy Bypass -Command "Invoke-WebRequest -Uri '%ZIP_URL%' -OutFile '%ZIP_PATH%' -UseBasicParsing"
if not exist "%ZIP_PATH%" (
    echo [ERROR] Failed to download the package.
    pause
    goto :MAIN_MENU
)

echo.
echo [4/6] Extracting to Desktop...
powershell -ExecutionPolicy Bypass -Command "Expand-Archive -Path '%ZIP_PATH%' -DestinationPath '%DESKTOP%' -Force"
del /F /Q "%ZIP_PATH%" >nul 2>&1

rem Determine Isaeva folder path
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
    pause
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
pause
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
    pause
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
pause
goto :MAIN_MENU
