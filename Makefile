TARGETS=env-build env-runtime cygwin-build cygwin-runtime gap-build \
        gap-runtime cygwin-extras-runtime
.PHONY: all $(TARGETS)

############################ Configurable Variables ###########################

ARCH=x86_64

GAP_VERSION?=master
GAP_BRANCH?=$(GAP_VERSION)
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
env-build=$(STAMPS)/env-build-$(GAP_VERSION)-$(ARCH)
env-runtime=$(STAMPS)/env-runtime-$(GAP_VERSION)-$(ARCH)
cygwin-build=$(STAMPS)/cygwin-build-$(GAP_VERSION)-$(ARCH)
cygwin-runtime=$(STAMPS)/cygwin-runtime-$(GAP_VERSION)-$(ARCH)
gap-build=$(STAMPS)/gap-build-$(GAP_VERSION)-$(ARCH)
gap-runtime=$(STAMPS)/gap-runtime-$(GAP_VERSION)-$(ARCH)
cygwin-runtime-extras=$(STAMPS)/cygwin-runtime-extras-$(GAP_VERSION)-$(ARCH)

###############################################################################

# Resource paths
CYGWIN_EXTRAS?=cygwin_extras
#RESOURCES?=resources
#ICONS:=$(wildcard $(RESOURCES)/*.bmp) $(wildcard $(RESOURCES)/*.ico)

ENV_BUILD_DIR=$(ENVS)/build-$(GAP_VERSION)-$(ARCH)
ENV_RUNTIME_DIR=$(ENVS)/runtime-$(GAP_VERSION)-$(ARCH)

GAP_ROOT=/opt/gap-$(GAP_VERSION)
GAP_ROOT_BUILD=$(ENV_BUILD_DIR)$(GAP_ROOT)
GAP_ROOT_RUNTIME=$(ENV_RUNTIME_DIR)$(GAP_ROOT)

N_CPUS=$(shell cat /proc/cpuinfo | grep '^processor' | wc -l)

# NOTE: Be very careful about quoting here; we need literal
# quotes or else they will be stripped when exec'ing bash
# NOTE: FFLAS_FFPACK_CONFIGURE is needed to work around a regression introduced
# in Sage 8.9: https://trac.sagemath.org/ticket/27444#comment:34
GAP_ENVVARS:=\
	GAP_NUM_THREADS=$(N_CPUS) \
	GAP_INSTALL_CCACHE=yes \
	CCACHE_DIR=\"$(HOME)/.ccache\" \
	GAP_FAT_BINARY=yes \
    FFLAS_FFPACK_CONFIGURE=--disable-openmp \
	MAKE=\"make -j$(N_CPUS)\"

GAP_OPTIONAL_PACKAGES=bliss coxeter3 mcqd primecount tdlib

# Outputs representing success in the GAP build process
GAP_STARTED?=$(GAP_ROOT_BUILD)/gap

# Files used as input to ISCC
GAP_ISS?=gap.iss
SOURCES:=$(GAP_ISS) #$(ICONS)

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

GAP_INSTALLER=$(DIST)/gap-$(GAP_VERSION)-v$(INSTALLER_VERSION).exe

TOOLS=tools
SUBCYG=$(TOOLS)/subcyg

DIRS=$(DIST) $(DOWNLOAD) $(ENVS) $(STAMPS)


################################################################################

all: $(GAP_INSTALLER)

$(GAP_INSTALLER): $(SOURCES) $(env-runtime) | $(DIST)
	@echo "::group::ISCC"
	cd $(CUDIR)
	$(ISCC) /DGapName=gap /DGapVersion=$(GAP_VERSION) /DGapArch=$(ARCH) /Q \
		/DInstallerVersion=$(INSTALLER_VERSION) \
		/DEnvsDir="$(ENVS)" /DOutputDir="$(DIST)" $(GAP_ISS)
	@echo "::endgroup::"


$(foreach target,$(TARGETS),$(eval $(target): $$($(target))))


$(env-runtime): $(cygwin-runtime) $(gap-runtime) $(cygwin-runtime-extras)
	@echo "::group::fixup-symlinks"
	$(TOOLS)/fixup-symlinks $(ENV_RUNTIME_DIR) > $(ENV_RUNTIME_DIR)/etc/symlinks.lst
	@echo "::endgroup::"
	@touch $@


$(gap-runtime): $(GAP_ROOT_RUNTIME)
	@touch $@

$(GAP_ROOT_RUNTIME): $(cygwin-runtime) $(gap-build)
	@echo "::group::gap-prep-runtime"
	@mkdir -p $(@D)
	cp -rp $(GAP_ROOT_BUILD) $(@D)
	# Prepare / compactify runtime environment
	$(TOOLS)/gap-prep-runtime "$(GAP_ROOT_RUNTIME)" "$(GAP_ROOT)"
	@echo "::endgroup::"


$(env-build): $(cygwin-build) $(gap-build)
	@touch $@


$(gap-build): $(cygwin-build) $(GAP_STARTED)
	# TODO: remove this, does nothing
	@touch $@


$(cygwin-runtime-extras): $(cygwin-runtime)
	@echo "::group::gap-prep-runtime-extras"
	$(TOOLS)/gap-prep-runtime-extras "$(ENV_RUNTIME_DIR)" "$(CYGWIN_EXTRAS)" \
		"$(GAP_VERSION)"
	@echo "::endgroup::"
	# Set apt-cyg to use a non-local mirror in the runtime env
	@echo "::group::apt-cyg mirror"
	$(SUBCYG) "$(ENV_RUNTIME_DIR)" "apt-cyg mirror $(CYGWIN_MIRROR)"
	@echo "::endgroup::"
	@touch $@


$(STAMPS)/cygwin-%: | $(ENVS)/% $(STAMPS)
	@touch $@

.SECONDARY: $(ENV_BUILD_DIR) $(ENV_RUNTIME_DIR)
$(ENVS)/%-$(GAP_VERSION)-$(ARCH): cygwin-gap-%-$(ARCH).list $(CYGWIN_SETUP)
	@echo "::group::cygwin setup"
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
	@echo "::endgroup::"


$(GAP_STARTED): | $(GAP_ROOT_BUILD)
	@echo "::group::get-gap"
	@mkdir -p $(dir $(GAP_ROOT_BUILD))
	mv ../gap-$(GAP_VERSION) $(GAP_ROOT_BUILD);
	@echo "::endgroup::"
	#
	@echo "::group::configure"
	$(SUBCYG) "$(ENV_BUILD_DIR)" "cd $(GAP_ROOT) && ./configure"
	@echo "::endgroup::"
	#
	@echo "::group::make"
	$(SUBCYG) "$(ENV_BUILD_DIR)" "cd $(GAP_ROOT) && make -j2"
	@echo "::endgroup::"
	#
	# build GAP packages
	@echo "::group::Build Packages"
	$(SUBCYG) "$(ENV_BUILD_DIR)" "cd $(GAP_ROOT)/pkg && (../bin/BuildPackages.sh --parallel || true)"
	@echo "::endgroup::"


$(GAP_ROOT_BUILD): $(cygwin-build)


$(CYGWIN_SETUP): | $(DOWNLOAD)
	@echo "::group::download"
	(cd $(DOWNLOAD) && wget "$(CYGWIN_SETUP_URL)")
	chmod +x $(CYGWIN_SETUP)
	@echo "::endgroup::"


$(DIRS):
	mkdir "$@"
