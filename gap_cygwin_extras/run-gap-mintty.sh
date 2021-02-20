#!/usr/bin/env bash

bash /run-gap.sh


if [ $? -ne 0 ]; then
    read -p "GAP exited with an error. Press Enter to close window"
fi