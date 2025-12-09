@echo off
setlocal enabledelayedexpansion

:: ============================================
:: GIT ACCOUNT SWITCHER v1.0
:: Easily switch between multiple GitHub accounts
:: Works on Windows (requires Git Bash/OpenSSH)
:: ============================================

set "CONFIG_DIR=%USERPROFILE%\.git-switcher"
set "CONFIG_FILE=%CONFIG_DIR%\accounts.txt"
set "SSH_DIR=%USERPROFILE%\.ssh"

:: Create config directory if not exists
if not exist "%CONFIG_DIR%" mkdir "%CONFIG_DIR%"

:: Check if first run (no accounts configured)
if not exist "%CONFIG_FILE%" goto first_run

:menu
cls
echo ======================================================
echo            GIT ACCOUNT SWITCHER v1.0
echo ======================================================
echo.

:: Show current account
for /f "tokens=*" %%a in ('git config --global user.name 2^>nul') do set "CURRENT_NAME=%%a"
for /f "tokens=*" %%a in ('git config --global user.email 2^>nul') do set "CURRENT_EMAIL=%%a"
echo   Current: %CURRENT_NAME% ^<%CURRENT_EMAIL%^>
echo.
echo ------------------------------------------------------
echo   ACCOUNTS:
echo ------------------------------------------------------

:: List accounts from config file
set "count=0"
for /f "tokens=1,2,3 delims=|" %%a in (%CONFIG_FILE%) do (
    set /a "count+=1"
    echo   !count!^) %%a  ^(%%b^)
)

if %count%==0 (
    echo   No accounts configured. Press 'a' to add one.
)

echo.
echo ------------------------------------------------------
echo   OPTIONS:
echo ------------------------------------------------------
echo   a^) Add new account
echo   r^) Remove account
echo   t^) Test GitHub SSH connection
echo   k^) Show current SSH public key
echo   h^) Help / Setup guide
echo   q^) Quit
echo ======================================================
echo.
set /p "choice=Select option: "

:: Check if numeric (account selection)
echo %choice%| findstr /r "^[0-9][0-9]*$" >nul
if not errorlevel 1 (
    if %choice% leq %count% if %choice% geq 1 (
        call :switch_to_account %choice%
        pause
        goto menu
    )
)

if /i "%choice%"=="a" goto add_account
if /i "%choice%"=="r" goto remove_account
if /i "%choice%"=="t" goto test_connection
if /i "%choice%"=="k" goto show_key
if /i "%choice%"=="h" goto show_help
if /i "%choice%"=="q" exit /b 0

echo Invalid option.
timeout /t 2 >nul
goto menu

:: ============================================
:: FIRST RUN - WELCOME & SETUP
:: ============================================
:first_run
cls
echo ======================================================
echo       WELCOME TO GIT ACCOUNT SWITCHER v1.0
echo ======================================================
echo.
echo   This tool helps you easily switch between multiple
echo   GitHub accounts on the same computer.
echo.
echo   WHAT IT DOES:
echo   - Switches git config (user.name, user.email)
echo   - Switches SSH keys for GitHub authentication
echo   - Generates SSH keys if needed
echo.
echo   REQUIREMENTS:
echo   - Git installed
echo   - OpenSSH installed (comes with Git for Windows)
echo.
echo ======================================================
echo.
echo   Let's set up your first GitHub account!
echo.
pause
goto add_account

:: ============================================
:: ADD NEW ACCOUNT
:: ============================================
:add_account
cls
echo ======================================================
echo               ADD NEW GITHUB ACCOUNT
echo ======================================================
echo.
echo   Enter the details for your GitHub account:
echo.
set /p "acc_name=  GitHub Username: "
if "%acc_name%"=="" goto menu

set /p "acc_email=  GitHub Email: "
if "%acc_email%"=="" goto menu

:: Create safe key filename (replace spaces with underscores)
set "key_name=id_ed25519_%acc_name: =_%"

echo.
echo ------------------------------------------------------
echo   Generating SSH key for %acc_name%...
echo ------------------------------------------------------

:: Create .ssh directory if not exists
if not exist "%SSH_DIR%" mkdir "%SSH_DIR%"

:: Check if key already exists
if exist "%SSH_DIR%\%key_name%" (
    echo.
    echo   SSH key already exists for this account.
    echo   Using existing key.
    goto :add_account_save
)

:: Generate new SSH key
ssh-keygen -t ed25519 -C "%acc_email%" -f "%SSH_DIR%\%key_name%" -N ""

if errorlevel 1 (
    echo.
    echo   ERROR: Failed to generate SSH key.
    echo   Make sure OpenSSH is installed.
    pause
    goto menu
)

:add_account_save
:: Save account to config file
echo %acc_name%^|%acc_email%^|%key_name%>> "%CONFIG_FILE%"

echo.
echo ======================================================
echo   ACCOUNT ADDED SUCCESSFULLY!
echo ======================================================
echo.
echo   NOW YOU NEED TO ADD THE SSH KEY TO GITHUB:
echo.
echo   1. Go to: https://github.com/settings/keys
echo      (Make sure you're logged in as %acc_name%)
echo.
echo   2. Click "New SSH key"
echo.
echo   3. Title: Enter any name (e.g., "My PC")
echo.
echo   4. Key type: Select "Authentication Key"
echo.
echo   5. Key: Copy and paste this PUBLIC key:
echo.
echo ------------------------------------------------------
type "%SSH_DIR%\%key_name%.pub"
echo.
echo ------------------------------------------------------
echo.
echo   6. Click "Add SSH key"
echo.
echo ======================================================
echo.
echo   The public key has also been copied to:
echo   %SSH_DIR%\%key_name%.pub
echo.
pause
goto menu

:: ============================================
:: SWITCH TO ACCOUNT
:: ============================================
:switch_to_account
set "target=%1"
set "idx=0"

for /f "tokens=1,2,3 delims=|" %%a in (%CONFIG_FILE%) do (
    set /a "idx+=1"
    if !idx!==%target% (
        set "sw_name=%%a"
        set "sw_email=%%b"
        set "sw_key=%%c"
    )
)

echo.
echo Switching to %sw_name%...

:: Set git config
git config --global user.name "%sw_name%"
git config --global user.email "%sw_email%"

:: Update SSH config
(
echo Host github.com
echo     HostName github.com
echo     User git
echo     IdentityFile ~/.ssh/%sw_key%
echo     IdentitiesOnly yes
) > "%SSH_DIR%\config"

echo.
echo ======================================================
echo   SWITCHED TO: %sw_name%
echo   Email: %sw_email%
echo   SSH Key: %sw_key%
echo ======================================================
echo.
goto :eof

:: ============================================
:: REMOVE ACCOUNT
:: ============================================
:remove_account
cls
echo ======================================================
echo              REMOVE GITHUB ACCOUNT
echo ======================================================
echo.
echo   Select account to remove:
echo.

set "count=0"
for /f "tokens=1,2,3 delims=|" %%a in (%CONFIG_FILE%) do (
    set /a "count+=1"
    echo   !count!^) %%a  ^(%%b^)
)

echo.
echo   c^) Cancel
echo.
set /p "rem_choice=Select: "

if /i "%rem_choice%"=="c" goto menu

echo %rem_choice%| findstr /r "^[0-9][0-9]*$" >nul
if errorlevel 1 goto menu

if %rem_choice% gtr %count% goto menu
if %rem_choice% lss 1 goto menu

:: Remove the selected line
set "idx=0"
set "removed_key="
> "%CONFIG_FILE%.tmp" (
    for /f "tokens=1,2,3 delims=|" %%a in (%CONFIG_FILE%) do (
        set /a "idx+=1"
        if not !idx!==%rem_choice% (
            echo %%a^|%%b^|%%c
        ) else (
            set "removed_name=%%a"
            set "removed_key=%%c"
        )
    )
)
move /y "%CONFIG_FILE%.tmp" "%CONFIG_FILE%" >nul

echo.
echo   Removed account: %removed_name%
echo.
set /p "del_key=  Delete SSH key file too? (y/n): "
if /i "%del_key%"=="y" (
    del "%SSH_DIR%\%removed_key%" 2>nul
    del "%SSH_DIR%\%removed_key%.pub" 2>nul
    echo   SSH key deleted.
)

pause
goto menu

:: ============================================
:: TEST CONNECTION
:: ============================================
:test_connection
cls
echo ======================================================
echo          TESTING GITHUB SSH CONNECTION
echo ======================================================
echo.
echo   Current account:
for /f "tokens=*" %%a in ('git config --global user.name 2^>nul') do echo   %% %%a
echo.
echo   Connecting to GitHub...
echo.
ssh -T git@github.com 2>&1
echo.
echo ======================================================
pause
goto menu

:: ============================================
:: SHOW CURRENT SSH KEY
:: ============================================
:show_key
cls
echo ======================================================
echo            CURRENT SSH PUBLIC KEY
echo ======================================================
echo.

:: Find current key from SSH config
set "current_key="
if exist "%SSH_DIR%\config" (
    for /f "tokens=2" %%a in ('findstr /i "IdentityFile" "%SSH_DIR%\config" 2^>nul') do (
        set "current_key=%%~nxa"
    )
)

if "%current_key%"=="" (
    echo   No SSH key currently configured.
    echo.
    pause
    goto menu
)

echo   Key file: %current_key%
echo.
echo   PUBLIC KEY (copy this to GitHub):
echo.
echo ------------------------------------------------------
if exist "%SSH_DIR%\%current_key%.pub" (
    type "%SSH_DIR%\%current_key%.pub"
) else (
    echo   Public key file not found.
)
echo.
echo ------------------------------------------------------
echo.
pause
goto menu

:: ============================================
:: HELP / SETUP GUIDE
:: ============================================
:show_help
cls
echo ======================================================
echo                    HELP / GUIDE
echo ======================================================
echo.
echo   HOW TO USE THIS TOOL:
echo.
echo   1. ADD ACCOUNTS
echo      Press 'a' to add a new GitHub account.
echo      You'll need your GitHub username and email.
echo      A new SSH key will be generated automatically.
echo.
echo   2. ADD SSH KEY TO GITHUB
echo      After adding an account, you MUST add the SSH
echo      public key to your GitHub account:
echo      - Go to https://github.com/settings/keys
echo      - Click "New SSH key"
echo      - Select "Authentication Key"
echo      - Paste the public key shown
echo.
echo   3. SWITCH ACCOUNTS
echo      Simply press the number of the account you
echo      want to switch to. This will update:
echo      - Git global user.name and user.email
echo      - SSH configuration for GitHub
echo.
echo   4. TEST CONNECTION
echo      Press 't' to verify your SSH connection works.
echo      You should see: "Hi username! You've successfully..."
echo.
echo   TROUBLESHOOTING:
echo.
echo   - "Permission denied (publickey)":
echo     The SSH key is not added to GitHub, or wrong
echo     account is selected. Add the key to GitHub.
echo.
echo   - SSH key generation fails:
echo     Make sure Git for Windows is installed with
echo     OpenSSH option enabled.
echo.
echo ======================================================
echo.
echo   Project: https://github.com/Vaixtrom/GitHub-Quick-Account-Switcher
echo.
pause
goto menu
