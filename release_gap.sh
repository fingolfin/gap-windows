#!/bin/sh


echo "::group::download"
mkdir -p download
(cd download && wget https://www.cygwin.com/setup-x86_64.exe)
chmod +x download/setup-x86_64.exe
echo "::endgroup::"


make
