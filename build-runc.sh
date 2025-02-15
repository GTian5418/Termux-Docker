#!/bin/bash
set -e
log() {
    echo ">>> $1"
}
log "Installing required packages..."
pkg install -y git build-essential golang make libseccomp libseccomp-static
log "Cloning repository..."
cd ~
rm -rf termux-packages
git clone https://github.com/termux/termux-packages.git
cd termux-packages
git checkout dd0d111e5057b9ee772b5167979db01227ba9024
log "Creating libc++ build script..."
cat > packages/libc++/build.sh << 'EOF'
TERMUX_PKG_HOMEPAGE=https://libcxx.llvm.org/
TERMUX_PKG_DESCRIPTION="C++ Standard Library"
TERMUX_PKG_LICENSE=NCSA
TERMUX_PKG_MAINTAINER=@termux
TERMUX_PKG_VERSION=27b
TERMUX_PKG_SRCURL=https://dl.google.com/android/repository/android-ndk-r27b-linux.zip
TERMUX_PKG_SHA256=33e16af1a6bbabe12cad54b2117085c07eab7e4fa67cdd831805f0e94fd826c1
TERMUX_PKG_AUTO_UPDATE=false
TERMUX_PKG_ESSENTIAL=true
TERMUX_PKG_BUILD_IN_SRC=true

termux_step_make_install() {
    mkdir -p $TERMUX_PREFIX/lib
    cp ./toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/lib/aarch64-linux-android/libc++_shared.so \
        $TERMUX_PREFIX/lib/
}
EOF
log "Building libc++..."
./build-package.sh packages/libc++
log "Creating runc build script..."
cat > root-packages/runc/build.sh << 'EOF'
TERMUX_PKG_HOMEPAGE=https://www.opencontainers.org/
TERMUX_PKG_DESCRIPTION="A tool for spawning and running containers according to the OCI specification"
TERMUX_PKG_LICENSE=Apache-2.0
TERMUX_PKG_MAINTAINER=@termux
TERMUX_PKG_VERSION=1.1.15
TERMUX_PKG_SRCURL=https://github.com/opencontainers/runc/archive/v${TERMUX_PKG_VERSION}.tar.gz
TERMUX_PKG_SHA256=8446718a107f3e437bc33a4c9b89b94cb24ae58ed0a49d08cd83ac7d39980860
TERMUX_PKG_AUTO_UPDATE=true
TERMUX_PKG_BUILD_IN_SRC=true
TERMUX_PKG_DEPENDS="libseccomp"
TERMUX_PKG_BUILD_DEPENDS="libseccomp-static"
termux_step_make() {
    export GOPATH=$HOME/go
    export CGO_ENABLED=1
    export CGO_LDFLAGS="-L$TERMUX_PREFIX/lib -lseccomp"
    export CGO_CFLAGS="-I$TERMUX_PREFIX/include"
    
    make BUILDTAGS="seccomp" \
        EXTRA_FLAGS="-buildmode=pie" \
        EXTRA_LDFLAGS="" \
        EXTRA_CFLAGS=""
}
termux_step_make_install() {
    install -Dm755 runc $TERMUX_PREFIX/bin/runc
}
EOF
log "Building runc..."
rm -rf /data/data/com.termux/files/home/.termux-build/runc
./build-package.sh root-packages/runc
log "Setting up version lock..."
mkdir -p $PREFIX/etc/apt/preferences.d
cat > $PREFIX/etc/apt/preferences.d/runc << 'EOF'
Package: runc
Pin: version 1.1.15
Pin-Priority: 1001

Package: runc
Pin: version *
Pin-Priority: -1
EOF
log "Verifying installation..."
if [ -f "$PREFIX/bin/runc" ]; then
    echo "Installation successful!"
    echo "runc version:"
    runc --version
else
    echo "Installation failed!"
    exit 1
fi
log "Updating package list..."
apt update
log "Checking runc policy..."
apt policy runc
log "Installation complete!"