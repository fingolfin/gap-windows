TARGETS=env-build env-runtime cygwin-build cygwin-runtime sage-build \
        sage-runtime cygwin-extras-runtime
.PHONY: all $(TARGETS) $(addprefix clean-,$(TARGETS)) clean-envs \
	    clean-installer clean-all

############################ Configurable Variables ###########################

ARCH=x86_64

# Set to 1 to build a test version of the installer for testing the installer
# itself itself; it excludes Sage but is faster to build and install
SAGE_TEST_INSTALLER?=0

SAGE_VERSION?=master
SAGE_BRANCH?=$(SAGE_VERSION)
INSTALLER_VERSION=0.6.3

# Output paths
DIST?=dist
DOWNLOAD?=download
ENVS?=envs
STAMPS?=.stamps

# Path to the Inno Setup executable
ISCC?="/cygdrive/c/Program Files (x86)/Inno Setup 6/ISCC.exe"

################################################################################

# Actual targets for the main build stages (the stamp files)
env-build=$(STAMPS)/env-build-$(SAGE_VERSION)-$(ARCH)
env-runtime=$(STAMPS)/env-runtime-$(SAGE_VERSION)-$(ARCH)
cygwin-build=$(STAMPS)/cygwin-build-$(SAGE_VERSION)-$(ARCH)
cygwin-runtime=$(STAMPS)/cygwin-runtime-$(SAGE_VERSION)-$(ARCH)
sage-build=$(STAMPS)/sage-build-$(SAGE_VERSION)-$(ARCH)
sage-runtime=$(STAMPS)/sage-runtime-$(SAGE_VERSION)-$(ARCH)
cygwin-runtime-extras=$(STAMPS)/cygwin-runtime-extras-$(SAGE_VERSION)-$(ARCH)

###############################################################################

# Resource paths
PATCHES?=patches
CYGWIN_EXTRAS?=cygwin_extras
#RESOURCES?=resources
#ICONS:=$(wildcard $(RESOURCES)/*.bmp) $(wildcard $(RESOURCES)/*.ico)

ENV_BUILD_DIR=$(ENVS)/build-$(SAGE_VERSION)-$(ARCH)
ENV_RUNTIME_DIR=$(ENVS)/runtime-$(SAGE_VERSION)-$(ARCH)

SAGE_GIT?=https://github.com/gap-system/gap
SAGE_ROOT=/opt/gap-$(SAGE_VERSION)
SAGE_ROOT_BUILD=$(ENV_BUILD_DIR)$(SAGE_ROOT)
SAGE_ROOT_RUNTIME=$(ENV_RUNTIME_DIR)$(SAGE_ROOT)

N_CPUS=$(shell cat /proc/cpuinfo | grep '^processor' | wc -l)

# NOTE: Be very careful about quoting here; we need literal
# quotes or else they will be stripped when exec'ing bash
# NOTE: FFLAS_FFPACK_CONFIGURE is needed to work around a regression introduced
# in Sage 8.9: https://trac.sagemath.org/ticket/27444#comment:34
SAGE_ENVVARS:=\
	SAGE_NUM_THREADS=$(N_CPUS) \
	SAGE_INSTALL_CCACHE=yes \
	CCACHE_DIR=\"$(HOME)/.ccache\" \
	SAGE_FAT_BINARY=yes \
    FFLAS_FFPACK_CONFIGURE=--disable-openmp \
	MAKE=\"make -j$(N_CPUS)\"

SAGE_OPTIONAL_PACKAGES=bliss coxeter3 mcqd primecount tdlib

# Outputs representing success in the Sage build process
SAGE_CONFIGURE=$(SAGE_ROOT_BUILD)/configure
SAGE_MAKEFILE?=$(SAGE_ROOT_BUILD)/Makefile
SAGE_STARTED?=$(SAGE_ROOT_BUILD)/local/etc/gap-started.txt

# Files used as input to ISCC
SAGEMATH_ISS?=gap.iss
SOURCES:=$(SAGEMATH_ISS) #$(ICONS)

# URL to download the Cygwin setup.exe
CYGWIN_SETUP_NAME=setup-$(ARCH).exe
CYGWIN_SETUP=$(DOWNLOAD)/$(CYGWIN_SETUP_NAME)
CYGWIN_SETUP_URL=https://www.cygwin.com/$(CYGWIN_SETUP_NAME)
CYGWIN_MIRROR=http://mirrors.kernel.org/sourceware/cygwin/
CYGWIN_LOCAL_MIRROR=cygwin_mirror/
ifeq (,$(wildcard $(CYGWIN_LOCAL_MIRROR)))
CYGWIN_LOCAL_INSTALL_FLAGS=
else
CYGWIN_MIRROR=$(CYGWIN_LOCAL_MIRROR)
CYGWIN_LOCAL_INSTALL_FLAGS=--local-install --local-package-dir "$$(cygpath -w -a .)"
endif

SAGE_INSTALLER=$(DIST)/gap-$(SAGE_VERSION)-v$(INSTALLER_VERSION).exe

TOOLS=tools
SUBCYG=$(TOOLS)/subcyg

DIRS=$(DIST) $(DOWNLOAD) $(ENVS) $(STAMPS)


################################################################################

all: $(SAGE_INSTALLER)

$(SAGE_INSTALLER): $(SOURCES) $(env-runtime) | $(DIST)
	cd $(CUDIR)
	$(ISCC) /DSageName=gap /DSageVersion=$(SAGE_VERSION) /DSageArch=$(ARCH) /Q \
		/DInstallerVersion=$(INSTALLER_VERSION) \
		/DSageTestInstaller=$(SAGE_TEST_INSTALLER) \
		/DEnvsDir="$(ENVS)" /DOutputDir="$(DIST)" $(SAGEMATH_ISS)

clean-installer:
	rm -f $(SAGE_INSTALLER)


$(foreach target,$(TARGETS),$(eval $(target): $$($(target))))


$(env-runtime): $(cygwin-runtime) $(sage-runtime) $(cygwin-runtime-extras)
	$(TOOLS)/fixup-symlinks $(ENV_RUNTIME_DIR) > $(ENV_RUNTIME_DIR)/etc/symlinks.lst
	@touch $@

clean-env-runtime: clean-cygwin-runtime
	rm -f $(env-runtime)


$(sage-runtime): $(SAGE_ROOT_RUNTIME)
	@touch $@

clean-sage-runtime:
	rm -rf $(SAGE_ROOT_RUNTIME)
	rm -f $(sage-runtime)


$(SAGE_ROOT_RUNTIME): $(cygwin-runtime) $(sage-build)
	[ -d $(dir $@) ] || mkdir $(dir $@)
	cp -rp $(SAGE_ROOT_BUILD) $(dir $@)
	# Prepare / compactify runtime environment
	$(TOOLS)/gap-prep-runtime "$(SAGE_ROOT_RUNTIME)" "$(SAGE_ROOT)"


$(env-build): $(cygwin-build) $(sage-build)
	@touch $@

clean-env-build: clean-sage-build clean-cygwin-build clean-installer
	rm -f $(env-build)

$(sage-build): $(cygwin-build) $(SAGE_STARTED)
	# TODO: remove this, does nothing
	@touch $@

clean-sage-build:
	rm -rf $(SAGE_ROOT_BUILD)
	rm -f $(sage-build)


$(cygwin-runtime-extras): $(cygwin-runtime)
	$(TOOLS)/gap-prep-runtime-extras "$(ENV_RUNTIME_DIR)" "$(CYGWIN_EXTRAS)" \
		"$(SAGE_VERSION)"
	# Set apt-cyg to use a non-local mirror in the runtime env
	$(SUBCYG) "$(ENV_RUNTIME_DIR)" "apt-cyg mirror $(CYGWIN_MIRROR)"
	@touch $@

# Right now the only effective way to roll back cygwin-runtime-extras
# is to clean the entire runtime cygwin environment
clean-cygwin-runtime-extras: clean-cygwin-runtime


$(STAMPS)/cygwin-%: | $(ENVS)/% $(STAMPS)
	@touch $@

clean-cygwin-build:
	rm -rf $(ENV_BUILD_DIR)
	rm -f $(cygwin-build)

clean-cygwin-runtime: clean-sage-runtime
	rm -rf $(ENV_RUNTIME_DIR)
	rm -f $(cygwin-runtime)
	rm -f $(cygwin-runtime-extras)

clean-envs: clean-env-runtime clean-env-build


clean-all: clean-envs clean-installer



.SECONDARY: $(ENV_BUILD_DIR) $(ENV_RUNTIME_DIR)
$(ENVS)/%-$(SAGE_VERSION)-$(ARCH): cygwin-gap-%-$(ARCH).list $(CYGWIN_SETUP)
	$(eval ENV_TMP := $(shell mktemp -d))
	"$(CYGWIN_SETUP)" --site $(CYGWIN_MIRROR) \
		$(CYGWIN_LOCAL_INSTALL_FLAGS) \
		--root "$$(cygpath -w -a $(ENV_TMP))" \
		--arch $(ARCH) --no-admin --no-shortcuts --quiet-mode \
		--packages $$($(TOOLS)/setup-package-list $<) \
		$(CYGWIN_SETUP_FLAGS)

	# Move the tmpdir into the final environment location
	mkdir -p $(ENVS)
	mv $(ENV_TMP) $@

	# Install symlinks for CCACHE
	if [ -x $@/usr/bin/ccache ]; then \
		ln -s /usr/bin/ccache $@/usr/local/bin/gcc; \
		ln -s /usr/bin/ccache $@/usr/local/bin/g++; \
	fi
	# A bit of cleanup
	rm -f $@/Cygwin*.{bat,ico}

	# We should re-touch the relevant stamp file since the runtime
	# environment may be updated
	touch "$(STAMPS)/cygwin-$(subst $(ENVS)/,,$@)"

SAGE_START_CMD?="cd $(SAGE_ROOT) && make"
SAGE_BUILD_PACKAGES?="cd $(SAGE_ROOT) && cd pkg && (../bin/BuildPackages.sh --parallel || true)"

$(SAGE_STARTED): $(SAGE_MAKEFILE)
	$(SUBCYG) "$(ENV_BUILD_DIR)" $(SAGE_START_CMD)
	# Install pre-installed optional packages and run make build again to
	# intall sagelib optional extensions that use those packages
	$(SUBCYG) "$(ENV_BUILD_DIR)" $(SAGE_BUILD_PACKAGES)
		


SAGE_RUN_CONFIGURE_CMD?="cd $(SAGE_ROOT) && make -j2"
$(SAGE_MAKEFILE): $(SAGE_CONFIGURE)
	$(SUBCYG) "$(ENV_BUILD_DIR)" $(SAGE_RUN_CONFIGURE_CMD)


SAGE_MAKE_CONFIGURE_CMD?="cd $(SAGE_ROOT) && ./configure"
$(SAGE_CONFIGURE): | $(SAGE_ROOT_BUILD)
	$(SUBCYG) "$(ENV_BUILD_DIR)" $(SAGE_MAKE_CONFIGURE_CMD)


$(SAGE_ROOT_BUILD): $(cygwin-build)
	[ -d $(dir $(SAGE_ROOT_BUILD)) ] || mkdir $(dir $(SAGE_ROOT_BUILD))
	# Get gap into the right place.
	#   If there exists neighbouring directory gap-$(SAGE_VERSION) e.g.
	#   gap-4.11.1, then use that version; move into $(SAGE_ROOT_BUILD).
	#   Else clone into $(SAGE_ROOT) using $(SAGE_GIT) & $(SAGE_BRANCH).
	# Note that $(SAGE_ROOT) = $(SAGE_ROOT_BUILD)/gap-$(SAGE_VERSION).
	if [ -d ../gap-$(SAGE_VERSION) ]; then \
		mv ../gap-$(SAGE_VERSION) $(SAGE_ROOT_BUILD); \
	else \
		$(SUBCYG) "$(ENV_BUILD_DIR)" "cd /opt && git clone --single-branch --branch $(SAGE_BRANCH) $(SAGE_GIT) $(SAGE_ROOT)"; \
	fi
	# Apply patches
	if [ -d $(PATCHES)/$(SAGE_BRANCH) ]; then \
		for patch in $(PATCHES)/$(SAGE_BRANCH)/*.patch; do \
		    patch="$$(pwd)/$$patch"; \
			(cd $(SAGE_ROOT_BUILD) && patch -p1 < $$patch); \
		done; \
	fi


$(CYGWIN_SETUP): | $(DOWNLOAD)
	(cd $(DOWNLOAD) && wget "$(CYGWIN_SETUP_URL)")
	chmod +x $(CYGWIN_SETUP)


$(DIRS):
	mkdir "$@"
