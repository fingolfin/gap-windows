#!/bin/sh

set -ex

#GAP_VERSION=master
INSTALLER_VERSION=0.6.3

# Path to the Inno Setup executable
ISCC="/cygdrive/c/Program Files (x86)/Inno Setup 6/ISCC.exe"


# Resource paths
CYGWIN_EXTRAS=cygwin_extras

ENV_BUILD_DIR=envs/build-${GAP_VERSION}-x86_64
ENV_RUNTIME_DIR=envs/runtime-${GAP_VERSION}-x86_64

GAP_ROOT=/opt/gap-${GAP_VERSION}
GAP_ROOT_BUILD=${ENV_BUILD_DIR}${GAP_ROOT}
GAP_ROOT_RUNTIME=${ENV_RUNTIME_DIR}${GAP_ROOT}

# URL to download the Cygwin setup.exe
CYGWIN_MIRROR=http://mirrors.kernel.org/sourceware/cygwin/

GAP_INSTALLER=dist/gap-${GAP_VERSION}-v${INSTALLER_VERSION}.exe


# download
echo "::group::download"
mkdir -p download
(cd download && wget https://www.cygwin.com/setup-x86_64.exe)
chmod +x download/setup-x86_64.exe
echo "::endgroup::"

# cygwin setup
echo "::group::cygwin setup build"
mkdir -p envs
download/setup-x86_64.exe --site ${CYGWIN_MIRROR} \
    --root "$(cygpath -w -a envs/build-${GAP_VERSION}-x86_64)" \
    --arch x86_64 --no-admin --no-shortcuts --quiet-mode \
    --packages $(tools/setup-package-list cygwin-gap-build-x86_64.list)

# Install symlinks for CCACHE
if [ -x envs/build-${GAP_VERSION}-x86_64/usr/bin/ccache ]; then
    ln -s /usr/bin/ccache envs/build-${GAP_VERSION}-x86_64/usr/local/bin/gcc
    ln -s /usr/bin/ccache envs/build-${GAP_VERSION}-x86_64/usr/local/bin/g++
fi
# A bit of cleanup
rm -f envs/build-${GAP_VERSION}-x86_64/Cygwin*.{bat,ico}
echo "::endgroup::"


# cygwin setup
echo "::group::cygwin setup runtime"
mkdir -p envs
download/setup-x86_64.exe --site ${CYGWIN_MIRROR} \
    --root "$(cygpath -w -a envs/runtime-${GAP_VERSION}-x86_64)" \
    --arch x86_64 --no-admin --no-shortcuts --quiet-mode \
    --packages $(tools/setup-package-list cygwin-gap-runtime-x86_64.list)

# Install symlinks for CCACHE
if [ -x envs/runtime-${GAP_VERSION}-x86_64/usr/bin/ccache ]; then
    ln -s /usr/bin/ccache envs/runtime-${GAP_VERSION}-x86_64/usr/local/bin/gcc
    ln -s /usr/bin/ccache envs/runtime-${GAP_VERSION}-x86_64/usr/local/bin/g++
fi
# A bit of cleanup
rm -f envs/runtime-${GAP_VERSION}-x86_64/Cygwin*.{bat,ico}
echo "::endgroup::"


echo "::group::get-gap"
mkdir -p $(dirname ${GAP_ROOT_BUILD})
mv ../gap-${GAP_VERSION} ${GAP_ROOT_BUILD};
echo "::endgroup::"

echo "::group::configure"
tools/subcyg "${ENV_BUILD_DIR}" "cd ${GAP_ROOT} && ./configure"
echo "::endgroup::"

echo "::group::make"
tools/subcyg "${ENV_BUILD_DIR}" "cd ${GAP_ROOT} && make -j2"
echo "::endgroup::"

# build GAP packages
echo "::group::Build Packages"
tools/subcyg "${ENV_BUILD_DIR}" "cd ${GAP_ROOT}/pkg && (../bin/BuildPackages.sh --parallel || true)"
echo "::endgroup::"

# gap-prep-runtime
echo "::group::gap-prep-runtime"
mkdir -p $(dirname ${GAP_ROOT_RUNTIME})
cp -rp ${GAP_ROOT_BUILD} $(dirname ${GAP_ROOT_RUNTIME})
# Prepare / compactify runtime environment
tools/gap-prep-runtime "${GAP_ROOT_RUNTIME}" "${GAP_ROOT}"
echo "::endgroup::"


# gap-prep-runtime-extras
echo "::group::gap-prep-runtime-extras"
tools/gap-prep-runtime-extras "${ENV_RUNTIME_DIR}" "${CYGWIN_EXTRAS}" "${GAP_VERSION}"
echo "::endgroup::"

# apt-cyg mirror
# Set apt-cyg to use a non-local mirror in the runtime env
echo "::group::apt-cyg mirror"
tools/subcyg "${ENV_RUNTIME_DIR}" "apt-cyg mirror ${CYGWIN_MIRROR}"
echo "::endgroup::"

# fixup-symlinks
echo "::group::fixup-symlinks"
tools/fixup-symlinks ${ENV_RUNTIME_DIR} > ${ENV_RUNTIME_DIR}/etc/symlinks.lst
echo "::endgroup::"

# ISCC
echo "::group::ISCC"
mkdir -p dist
#cd ${CUDIR}
"${ISCC}" /DGapName=gap /DGapVersion=${GAP_VERSION} /DGapArch=x86_64 /Q \
    /DInstallerVersion=${INSTALLER_VERSION} \
    /DEnvsDir="envs" /DOutputDir="dist" gap.iss
echo "::endgroup::"
