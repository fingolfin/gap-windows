@echo off
setlocal enableextensions
set TERM=
cd /d "%~dp0\runtime\bin"
.\cygstart .\bash --login /run-gap.sh
