@ECHO OFF
SETLOCAL
REM 
REM tfalias.cmd : TerraformUtil for command prompt
REM 
pwsh -NonInteractive -NoProfile -Command "%~dp0tfalias.ps1" %*
ENDLOCAL
