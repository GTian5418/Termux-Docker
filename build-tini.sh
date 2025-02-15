#!/bin/bash

# 设置错误时退出
set -e

# 设置环境变量
export TMPDIR=/data/data/com.termux/files/usr/tmp
export PREFIX=/data/data/com.termux/files/usr

# 输出步骤信息的函数
log() {
    echo ">>> $1"
}

# 清理旧的构建目录
log "Cleaning old build directory"
rm -rf $TMPDIR/docker-build
mkdir -p $TMPDIR/docker-build
cd $TMPDIR/docker-build

# 下载并解压源码
log "Downloading and extracting source code"
wget https://github.com/krallin/tini/archive/v0.19.0.tar.gz
tar xf v0.19.0.tar.gz
cd tini-0.19.0

# 修复函数声明
log "Fixing function declarations"
sed -i 's/\([a-zA-Z_][a-zA-Z0-9_]*\s\+[a-zA-Z_][a-zA-Z0-9_]*\s*\)()[ ]*{/\1(void) {/g' src/tini.c

# 创建并配置 CMakeLists.txt
log "Creating CMakeLists.txt"
cat > CMakeLists.txt << 'EOF'
cmake_minimum_required(VERSION 3.10)
project(tini C)

# Set compilation options
option(MINIMAL "Optimize for size" OFF)

# Configure version
set(tini_VERSION_MAJOR 0)
set(tini_VERSION_MINOR 19)
set(tini_VERSION_PATCH 0)
set(TINI_VERSION "${tini_VERSION_MAJOR}.${tini_VERSION_MINOR}.${tini_VERSION_PATCH}")

# Configure header file
configure_file(
  "${PROJECT_SOURCE_DIR}/src/tiniConfig.h.in"
  "${PROJECT_BINARY_DIR}/tiniConfig.h"
)

# Include binary directory for tiniConfig.h
include_directories("${PROJECT_BINARY_DIR}")

# Set source files
set(tini_SOURCES src/tini.c)

# Add main executable
add_executable(tini ${tini_SOURCES})

# Handle minimal build
if(MINIMAL)
  target_compile_definitions(tini PRIVATE -DMINIMAL=1)
endif()

# Add version definitions
target_compile_definitions(tini PRIVATE
  TINI_VERSION="${TINI_VERSION}"
)

# Installation
install(TARGETS tini
        RUNTIME DESTINATION bin)
EOF

# 创建配置头文件模板
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

# 构建和安装
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

# 创建 docker-init 符号链接
log "Creating docker-init symlink"
ln -sf $PREFIX/bin/tini $PREFIX/bin/docker-init

# 验证安装
log "Verifying installation"
if [ -f "$PREFIX/bin/docker-init" ]; then
    echo "Installation successful!"
    echo "Version information:"
    $PREFIX/bin/docker-init --version
else
    echo "Installation failed!"
    exit 1
fi