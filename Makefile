TARGETS=env-build env-runtime cygwin-build cygwin-runtime gap-build \
        gap-runtime cygwin-extras-runtime
.PHONY: all $(TARGETS)

############################ Configurable Variables ###########################

GAP_VERSION?=master
INSTALLER_VERSION=0.6.3

# Path to the Inno Setup executable
ISCC?="/cygdrive/c/Program Files (x86)/Inno Setup 6/ISCC.exe"

################################################################################

# Actual targets for the main build stages (the stamp files)
env-build=.stamps/env-build-$(GAP_VERSION)-x86_64
env-runtime=.stamps/env-runtime-$(GAP_VERSION)-x86_64
cygwin-build=.stamps/cygwin-build-$(GAP_VERSION)-x86_64
cygwin-runtime=.stamps/cygwin-runtime-$(GAP_VERSION)-x86_64
gap-build=.stamps/gap-build-$(GAP_VERSION)-x86_64
gap-runtime=.stamps/gap-runtime-$(GAP_VERSION)-x86_64
cygwin-runtime-extras=.stamps/cygwin-runtime-extras-$(GAP_VERSION)-x86_64

###############################################################################

# Resource paths
CYGWIN_EXTRAS?=cygwin_extras

ENV_BUILD_DIR=envs/build-$(GAP_VERSION)-x86_64
ENV_RUNTIME_DIR=envs/runtime-$(GAP_VERSION)-x86_64

GAP_ROOT=/opt/gap-$(GAP_VERSION)
GAP_ROOT_BUILD=$(ENV_BUILD_DIR)$(GAP_ROOT)
GAP_ROOT_RUNTIME=$(ENV_RUNTIME_DIR)$(GAP_ROOT)

# URL to download the Cygwin setup.exe
CYGWIN_MIRROR=http://mirrors.kernel.org/sourceware/cygwin/

GAP_INSTALLER=dist/gap-$(GAP_VERSION)-v$(INSTALLER_VERSION).exe


################################################################################

all: $(GAP_INSTALLER)

$(GAP_INSTALLER): gap.iss $(env-runtime)
	@echo "::group::ISCC"
	mkdir -p dist
	cd $(CUDIR)
	$(ISCC) /DGapName=gap /DGapVersion=$(GAP_VERSION) /DGapArch=x86_64 /Q \
		/DInstallerVersion=$(INSTALLER_VERSION) \
		/DEnvsDir="envs" /DOutputDir="dist" gap.iss
	@echo "::endgroup::"


$(foreach target,$(TARGETS),$(eval $(target): $$($(target))))


$(env-runtime): $(cygwin-runtime) $(gap-runtime) $(cygwin-runtime-extras)
	@echo "::group::fixup-symlinks"
	tools/fixup-symlinks $(ENV_RUNTIME_DIR) > $(ENV_RUNTIME_DIR)/etc/symlinks.lst
	@echo "::endgroup::"
	@touch $@


$(gap-runtime): $(GAP_ROOT_RUNTIME)
	@touch $@

$(GAP_ROOT_RUNTIME): $(cygwin-runtime) $(gap-build)
	@echo "::group::gap-prep-runtime"
	@mkdir -p $(@D)
	cp -rp $(GAP_ROOT_BUILD) $(@D)
	# Prepare / compactify runtime environment
	tools/gap-prep-runtime "$(GAP_ROOT_RUNTIME)" "$(GAP_ROOT)"
	@echo "::endgroup::"


$(env-build): $(cygwin-build) $(gap-build)
	@touch $@


$(gap-build): $(cygwin-build) $(GAP_ROOT_BUILD)/gap
	# TODO: remove this, does nothing
	@touch $@


$(cygwin-runtime-extras): $(cygwin-runtime)
	@echo "::group::gap-prep-runtime-extras"
	tools/gap-prep-runtime-extras "$(ENV_RUNTIME_DIR)" "$(CYGWIN_EXTRAS)" \
		"$(GAP_VERSION)"
	@echo "::endgroup::"
	# Set apt-cyg to use a non-local mirror in the runtime env
	@echo "::group::apt-cyg mirror"
	tools/subcyg "$(ENV_RUNTIME_DIR)" "apt-cyg mirror $(CYGWIN_MIRROR)"
	@echo "::endgroup::"
	@touch $@


.stamps/cygwin-%: | envs/%
	mkdir -p .stamps
	@touch $@

.SECONDARY: $(ENV_BUILD_DIR) $(ENV_RUNTIME_DIR)
envs/%-$(GAP_VERSION)-x86_64: cygwin-gap-%-x86_64.list
	@echo "::group::cygwin setup"
	$(eval ENV_TMP := $(shell mktemp -d))
	download/setup-x86_64.exe --site $(CYGWIN_MIRROR) \
		--root "$$(cygpath -w -a $(ENV_TMP))" \
		--arch x86_64 --no-admin --no-shortcuts --quiet-mode \
		--packages $$(tools/setup-package-list $<) \
		$(CYGWIN_SETUP_FLAGS)

	# Move the tmpdir into the final environment location
	mkdir -p envs
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
	touch ".stamps/cygwin-$(subst envs/,,$@)"
	@echo "::endgroup::"


$(GAP_ROOT_BUILD)/gap: | $(GAP_ROOT_BUILD)
	@echo "::group::get-gap"
	@mkdir -p $(dir $(GAP_ROOT_BUILD))
	mv ../gap-$(GAP_VERSION) $(GAP_ROOT_BUILD);
	@echo "::endgroup::"
	#
	@echo "::group::configure"
	tools/subcyg "$(ENV_BUILD_DIR)" "cd $(GAP_ROOT) && ./configure"
	@echo "::endgroup::"
	#
	@echo "::group::make"
	tools/subcyg "$(ENV_BUILD_DIR)" "cd $(GAP_ROOT) && make -j2"
	@echo "::endgroup::"
	#
	# build GAP packages
	@echo "::group::Build Packages"
	tools/subcyg "$(ENV_BUILD_DIR)" "cd $(GAP_ROOT)/pkg && (../bin/BuildPackages.sh --parallel || true)"
	@echo "::endgroup::"


$(GAP_ROOT_BUILD): $(cygwin-build)


envs .stamps:
	mkdir -p "$@"
