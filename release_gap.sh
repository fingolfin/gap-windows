#!/bin/sh

make --trace \
    SAGE_STARTED='"$(SAGE_ROOT)/pkg/log"' \
    SAGE_STARTED='"$(SAGE_ROOT_BUILD)/gap"'
