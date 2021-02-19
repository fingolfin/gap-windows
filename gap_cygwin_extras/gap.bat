@echo off
setlocal enableextensions
set TERM=
cd /d "%~dp0bin"
start .\bash --login /run-gap.sh
