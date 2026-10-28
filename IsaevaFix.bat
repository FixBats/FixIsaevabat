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
echo   4. Restore from Backup
echo   5. Test Output
echo   6. Exit
echo.
set /p CHOICE=Enter your choice (1-6): 
if "%CHOICE%"=="1" goto :ISAEVA_FIX
if "%CHOICE%"=="2" goto :LOGIN_INJECTION_FIX
if "%CHOICE%"=="3" goto :RUNTIME_FIX
if "%CHOICE%"=="4" goto :RESTORE_BACKUP
if "%CHOICE%"=="5" goto :TEST_OUTPUT
if "%CHOICE%"=="6" exit /b
echo Invalid choice. Please try again.
timeout /t 2 >nul
goto :MAIN_MENU
