@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0"

set REPO_URL=https://github.com/SteveP999/borrowed-whispers.git
set REPO_NAME=borrowed-whispers
set LOG_FILE=update-log.txt

call :main > "%LOG_FILE%" 2>&1
set EXIT_CODE=%ERRORLEVEL%

type "%LOG_FILE%"
echo.

if "%EXIT_CODE%"=="0" (
  echo SUCCESS! %REPO_NAME% is live.
) else (
  echo ERROR: HTR update failed.
  echo The full log is saved here:
  echo %CD%\%LOG_FILE%
)

echo.
echo Finished. Press any key to close.
pause
exit /b %EXIT_CODE%

:main
echo.
echo ==========================================
echo  HTR Update - %REPO_NAME%
echo ==========================================
echo.
echo Running from: %CD%
echo.

where git >nul 2>nul
if errorlevel 1 (
  echo ERROR: Git is not installed or not available in PATH.
  echo Install Git for Windows, then run this again.
  exit /b 1
)

if "%REPO_URL%"=="" (
  echo ERROR: No GitHub remote URL was generated for this artist.
  echo Check githubRepo in D:\HTR-Control-Center\datartists.json.
  exit /b 1
)

if not exist ".git" (
  echo No local Git repo found. Initializing this artist folder...
  git init
  if errorlevel 1 exit /b 1
)

git branch -M main
if errorlevel 1 exit /b 1

git remote get-url origin >nul 2>nul
if errorlevel 1 (
  echo No Git remote found. Adding origin...
  git remote add origin "%REPO_URL%"
  if errorlevel 1 exit /b 1
) else (
  for /f "delims=" %%r in ('git remote get-url origin') do set CURRENT_REMOTE=%%r
  if /I not "!CURRENT_REMOTE!"=="%REPO_URL%" (
    echo Existing remote found: !CURRENT_REMOTE!
    echo Expected remote: %REPO_URL%
    echo Replacing origin remote with expected URL.
    git remote set-url origin "%REPO_URL%"
    if errorlevel 1 exit /b 1
  )
)

echo.
echo Checking GitHub for an existing main branch...
git fetch origin main >nul 2>nul
set HAS_REMOTE=0
if not errorlevel 1 set HAS_REMOTE=1

if "%HAS_REMOTE%"=="1" (
  echo Remote main branch found.
) else (
  echo No existing remote main branch found. This appears to be a first push.
)

echo.
echo Staging generated site files...
git add -A
if errorlevel 1 exit /b 1

git diff --cached --quiet
if errorlevel 1 (
  echo.
  git status
  echo.
  set /p msg=Commit message ^(Enter = update artist site^): 
  if "!msg!"=="" set msg=update artist site
  git commit -m "!msg!"
  if errorlevel 1 exit /b 1
) else (
  echo No local changes to commit before sync.
)

if "%HAS_REMOTE%"=="1" (
  echo.
  echo Syncing with GitHub after local commit, keeping generated files if conflicts happen...
  git pull origin main --allow-unrelated-histories --no-rebase -X ours
  if errorlevel 1 (
    echo.
    echo ERROR: Git pull still needs manual conflict resolution.
    echo No files were deleted by this script.
    exit /b 1
  )
)

echo.
echo Pushing to GitHub...
git push -u origin main
if errorlevel 1 exit /b 1

exit /b 0
