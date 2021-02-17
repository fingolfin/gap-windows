make \
    SAGE_GIT=https://www.github.com/gap-system/gap \
    SAGE_VERSION=master \
    SAGE_MAKE_CONFIGURE_CMD?='"cd $(SAGE_ROOT) && ./autogen.sh && ./configure"'
    SAGE_MAKEFILE='$(SAGE_ROOT_BUILD)/Makefile' \
    PROGBASE=gap
