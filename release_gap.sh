make --trace \
    SAGE_GIT=https://www.github.com/ChrisJefferson/gap \
    SAGE_VERSION=cygwin-fixes \
    SAGE_MAKE_CONFIGURE_CMD?='"cd $(SAGE_ROOT) && ./autogen.sh && ./configure"' \
    SAGE_RUN_CONFIGURE_CMD?='"cd $(SAGE_ROOT) && make && make bootstrap-pkg-full"' \
    SAGE_MAKEFILE='$(SAGE_ROOT_BUILD)/Makefile' \
    SAGE_START_CMD='"cd $(SAGE_ROOT) && make bootstrap-pkg-full"' \
    SAGE_BUILD_PACKAGES='"cd $(SAGE_ROOT) && cd pkg && ../bin/BuildPackages.sh --parallel "' \
    SAGE_STARTED='"$(SAGE_ROOT_BUILD)/gap"' \
    SAGE_REBUILD_CMD='"true"' \
    SAGE_BUILD_DOC_CMD='"cd $(SAGE_ROOT)" && make doc' \
    PROGBASE=gap \
    PROG=gap \
    ISCC='"/cygdrive/c/Program Files (x86)/Inno Setup 6/ISCC.exe"' \
    SAGEMATH_ISS?=gap.iss \
    CYGWIN_EXTRAS=gap_cygwin_extras \
    SAGE_REBASE_CMD='"true"' \
    SAGE_FIXUP_DOC_CMD='"true"'


#    SAGE_BUILD_DOC_CMD='"cd $(SAGE_ROOT) && make doc"' \


#    SAGE_BUILD_DOC_CMD='"cd $(SAGE_ROOT) && make doc"' \
#        SAGE_BUILD_PACKAGES='"cd $(SAGE_ROOT) && cd pkg # && ../bin/BuildPackages.sh --parallel "' \
