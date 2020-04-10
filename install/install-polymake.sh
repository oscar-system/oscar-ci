#!/bin/bash
set -e
source meta/stdenv.sh
set -x
cd polymake
./configure --prefix="$WORKSPACE/local"
ninja -C build/Opt -j"$BUILDJOBS"
ninja -C build/Opt install
