@echo off
setlocal

if defined GRFT_HOME (
  set "GET_PS1=%GRFT_HOME%\get.ps1"
) else (
  set "GET_PS1=%USERPROFILE%\.grft\get.ps1"
)

if not exist "%GET_PS1%" (
  echo grft is not installed. Run: irm https://raw.githubusercontent.com/grft-dev/graftcode/refs/heads/main/cli/install.ps1 ^| iex
  exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%GET_PS1%" %*
exit /b %ERRORLEVEL%
