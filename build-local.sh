#!/bin/bash

set -euo pipefail

WORKDIR=~/workdir/openwrt

echo "#####Clone Repos && Environment Preperation##########"
mkdir -p "$WORKDIR"
git clone https://github.com/immortalwrt/immortalwrt -b master "$WORKDIR"
cp -R ./* "$WORKDIR"
cd "$WORKDIR"
chmod +x scripts/environment.sh && ./scripts/environment.sh
sudo bash -c 'bash <(curl -s https://build-scripts.immortalwrt.org/init_build_environment.sh)'


echo "######## Feeds Update  ########"
cd "$WORKDIR"
./scripts/feeds update -a && ./scripts/feeds install -a
chmod +x ./scripts/O23-SNAPSHOT/diy.sh && ./scripts/O23-SNAPSHOT/diy.sh

echo "#####Patch && Download"
cd "$WORKDIR"
cat configs/Packages-x86.txt >> .config
chmod +x ./scripts/preset-clash-core-x86.sh && ./scripts/preset-clash-core-x86.sh
make defconfig
make download -j$(nproc) V=s
find dl -size -1024c -exec ls -l {} \;
find dl -size -1024c -exec rm -f {} \;

echo "###### Compiling ########"
cd "$WORKDIR"
echo -e "$((($(nproc)+1))) thread compile"
make tools/compile -j$(($(nproc)+1))
make toolchain/compile -j$(($(nproc)+1))
make package/feeds/luci/luci-base/compile
 make -j$(($(nproc)+1)) || make -j$(nproc) || make -j1 V=s