@echo off
setlocal enableextensions
set TERM=
cd /d "%~dp0\runtime\bin"
mintty.exe -s 120,40 --icon ..\..\gapicon.ico --Title GAP .\bash --login /run-gap-mintty.sh
