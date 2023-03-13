#!/bin/sh

make --trace \
    SAGE_MAKE_CONFIGURE_CMD?='"cd $(SAGE_ROOT) && ./autogen.sh && ./configure"' \
    SAGE_RUN_CONFIGURE_CMD?='"cd $(SAGE_ROOT) && make && make bootstrap-pkg-full"' \
    SAGE_STARTED='"$(SAGE_ROOT)/pkg/log"' \
    SAGE_STARTED='"$(SAGE_ROOT_BUILD)/gap"'
