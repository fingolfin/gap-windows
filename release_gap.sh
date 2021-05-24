#!/bin/sh

make --trace \
    SAGE_GIT?=https://github.com/gap-system/gap \
    SAGE_VERSION?=master \
    SAGE_MAKE_CONFIGURE_CMD?='"cd $(SAGE_ROOT) && ./autogen.sh && ./configure"' \
    SAGE_RUN_CONFIGURE_CMD?='"cd $(SAGE_ROOT) && make && make bootstrap-pkg-full"' \
    SAGE_MAKEFILE='$(SAGE_ROOT_BUILD)/Makefile' \
    SAGE_START_CMD='"cd $(SAGE_ROOT) && make"' \
    SAGE_STARTED='"$(SAGE_ROOT)/pkg/log"' \
    SAGE_BUILD_PACKAGES='"cd $(SAGE_ROOT) && cd pkg && (../bin/BuildPackages.sh --parallel || true)"' \
    SAGE_STARTED='"$(SAGE_ROOT_BUILD)/gap"' \
    SAGE_REBUILD_CMD='"true"' \
    SAGE_BUILD_DOC_CMD?='"cd $(SAGE_ROOT) && make doc"' \
    PROGBASE=gap \
    PROG=gap \
    ISCC='"/cygdrive/c/Program Files (x86)/Inno Setup 6/ISCC.exe"' \
    SAGEMATH_ISS?=gap.iss \
    CYGWIN_EXTRAS=gap_cygwin_extras \
    SAGE_REBASE_CMD='"true"' \
    SAGE_FIXUP_DOC_CMD='"true"' $*
