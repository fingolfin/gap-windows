#!/bin/sh

make --trace \
    SAGE_VERSION?=master \
    SAGE_MAKE_CONFIGURE_CMD?='"cd $(SAGE_ROOT) && ./autogen.sh && ./configure"' \
    SAGE_RUN_CONFIGURE_CMD?='"cd $(SAGE_ROOT) && make && make bootstrap-pkg-full"' \
    SAGE_MAKEFILE='$(SAGE_ROOT_BUILD)/Makefile' \
    SAGE_START_CMD='"cd $(SAGE_ROOT) && make"' \
    SAGE_STARTED='"$(SAGE_ROOT)/pkg/log"' \
    SAGE_BUILD_PACKAGES='"cd $(SAGE_ROOT) && cd pkg && (../bin/BuildPackages.sh --parallel || true)"' \
    SAGE_STARTED='"$(SAGE_ROOT_BUILD)/gap"'
