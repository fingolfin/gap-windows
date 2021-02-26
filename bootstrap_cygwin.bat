SETLOCAL
 
REM -- Change to the directory of the executing batch file
CD %~dp0

REM -- Get cygwin
curl https://www.cygwin.com/setup-x86_64.exe --output setup-x86_64.exe

REM -- Configure paths
SET SITE=http://cygwin.mirrors.pair.com/
SET LOCALDIR=%CD%
SET ROOTDIR=%~dp0\cygwin_bootstrap
ECHO %ROOTDIR%
 
REM -- These are the packages we will install (in addition to the default packages)
SET PACKAGES=wget,git,patch

REM -- Do it!
ECHO.
ECHO *** SETTING UP CYGWIN
setup-x86_64 -W --quiet-mode --no-desktop --no-admin --no-startmenu --no-shortcuts  -s %SITE% -l "%LOCALDIR%" -R "%ROOTDIR%" -P %PACKAGES%

ENDLOCAL

EXIT /B 0
