@ECHO OFF
SETLOCAL
REM 
REM terraform.cmd : Shim for terraform binary. 
REM 
pwsh -NonInteractive -NoProfile -Command "%~dp0terraform.ps1" %*
ENDLOCAL
