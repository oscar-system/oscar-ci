#!/bin/bash
set -e
source meta/stdenv.sh
set -x
cd julia
make -j"$JOBS"
ln -sf "$WORKSPACE/julia/julia" "$WORKSPACE/local/bin"
