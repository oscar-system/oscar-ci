#!/bin/bash
set -e
source meta/stdenv.sh
set -x
cd julia
make -j"$BUILDJOBS"
ln -sf "$WORKSPACE/julia/julia" "$WORKSPACE/local/bin"
