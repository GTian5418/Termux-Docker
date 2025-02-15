# Docker-native-on-Termux-on-Android
You can now run Docker on Android with Termux and it's sub-packages

## How-To
First thing first you require is supported kernel with docker required config flags turned on and rooted device.You can search with your device code name with docker on GitHub because if someone has already compiled for your device
than you do not have to compile it. To search for it I would like to do in GitHub search is

- my device is k20 pro and it's codename is "Raphael"
so I will search for "Raphael docker kernel"
and if you find any compiled kernel than go with it otherwise you have to compile it by your self
trust me compiling kernel is very easy only you need is pc or laptop with minimum Intel-i3 or AMD-Athlon processor with UBUNTU
OR any other Debian based Linux OS installed
I will add easy steps for compiling kernel latter...

## Installation process
now I assume you have docker compatible kernel on your device now you need to install [termux](https://github.com/termux/termux-app/actions/workflows/debug_build.yml) on your device and open app and enter this commands:

## Termux-Docker

```bash
pkg install root-repo && pkg install docker
pkg install wget golang make cmake ndk-multilib tsu dnsutils iproute2
```
after that you have to install tini but you have to compile it manually on your device with

```bash
#!/bin/bash
set -e
export TMPDIR=/data/data/com.termux/files/usr/tmp
export PREFIX=/data/data/com.termux/files/usr
log() {
    echo ">>> $1"
}
log "Cleaning old build directory"
rm -rf $TMPDIR/docker-build
mkdir -p $TMPDIR/docker-build
cd $TMPDIR/docker-build
log "Downloading and extracting source code"
wget https://github.com/krallin/tini/archive/v0.19.0.tar.gz
tar xf v0.19.0.tar.gz
cd tini-0.19.0
log "Fixing function declarations"
sed -i 's/\([a-zA-Z_][a-zA-Z0-9_]*\s\+[a-zA-Z_][a-zA-Z0-9_]*\s*\)()[ ]*{/\1(void) {/g' src/tini.c
log "Creating CMakeLists.txt"
cat > CMakeLists.txt << 'EOF'
cmake_minimum_required(VERSION 3.10)
project(tini C)
option(MINIMAL "Optimize for size" OFF)
set(tini_VERSION_MAJOR 0)
set(tini_VERSION_MINOR 19)
set(tini_VERSION_PATCH 0)
set(TINI_VERSION "${tini_VERSION_MAJOR}.${tini_VERSION_MINOR}.${tini_VERSION_PATCH}")
configure_file(
  "${PROJECT_SOURCE_DIR}/src/tiniConfig.h.in"
  "${PROJECT_BINARY_DIR}/tiniConfig.h"
)
include_directories("${PROJECT_BINARY_DIR}")
set(tini_SOURCES src/tini.c)
add_executable(tini ${tini_SOURCES})
if(MINIMAL)
  target_compile_definitions(tini PRIVATE -DMINIMAL=1)
endif()
target_compile_definitions(tini PRIVATE
  TINI_VERSION="${TINI_VERSION}"
)
install(TARGETS tini
        RUNTIME DESTINATION bin)
EOF
log "Creating configuration header template"
cat > src/tiniConfig.h.in << 'EOF'
#ifndef TINI_CONFIG_H
#define TINI_CONFIG_H
#define TINI_VERSION_MAJOR @tini_VERSION_MAJOR@
#define TINI_VERSION_MINOR @tini_VERSION_MINOR@
#define TINI_VERSION_PATCH @tini_VERSION_PATCH@
#define TINI_VERSION "@TINI_VERSION@"
#define TINI_GIT ""
#endif
EOF
log "Building tini"
mkdir -p build
cd build
cmake \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=$PREFIX \
  -DMINIMAL=ON \
  ..
make -j$(nproc)
make install
log "Creating docker-init symlink"
ln -sf $PREFIX/bin/tini $PREFIX/bin/docker-init
log "Verifying installation"
if [ -f "$PREFIX/bin/docker-init" ]; then
    echo "Installation successful!"
    echo "Version information:"
    $PREFIX/bin/docker-init --version
else
    echo "Installation failed!"
    exit 1
fi
```

## Get some useful scripts
```bash
cd ~
pkg install wget
mkdir dhs
cd dhs
wget https://raw.githubusercontent.com/GTian5418/Termux-Docker/refs/heads/main/docker.sh
wget https://raw.githubusercontent.com/GTian5418/Termux-Docker/refs/heads/main/network.sh
chmod 777 docker.sh && chmod 777 network.sh
```
## Hacks
 
Now add some shortcut commands to our bashrc to make alias of our commands. Open it and then copy paste text mentioned below
 
```bash
cd ~
nano /data/data/com.termux/files/usr/etc/bash.bashrc
```
and add this text to it..
I also added some useful alias I am using.
 
```bash
# It will make folder and cd in to it directly
mkcdir ()
{
    mkdir -p -- "$1" &&
       cd -P -- "$1"
}
alias ud="pkg update && pkg upgrade"
alias pki="pkg install"
alias alias="nano /data/data/com.termux/files/usr/etc/bash.bashrc && cd ~"
alias ds="sudo bash ~/dhs/docker.sh"
alias ns="sudo bash ~/dhs/network.sh"
alias docker="sudo docker"
alias k="kubectl"
alias nano="nano -m"
alias cl="clear"
alias q="exit"
```
now save file and exit from termux and restart termux app

# Run docker

```bash
# now to start docker you only have to type command "ns" for network and "ds" for docker daemon to start

ns
ds
```
Everytime you chenge network you also have to run network script with "ns" command 
Now you can run docker successfully

Thanks to:
- [FreddieOliveira](https://github.com/FreddieOliveira) for making it work for android.
- [termux](https://github.com/termux) for their amazing app.
- [Docker on Android](https://gist.github.com/FreddieOliveira/efe850df7ff3951cb62d74bd770dce27#3-running) complete guide for running docker.
- [K20pro Docker Kernel](https://blog.csdn.net/qq_39341687/article/details/134996369) tutorial for flashing docker-compatible kernel.
- [Docker-native-on](https://github.com/Morakhiyasaiyam/Docker-native-on-Termux-on-Android) -Termux-on-Android

