#!/bin/bash
set -e
source meta/stdenv.sh
set -x
ln -sf "$(julia meta/gappath.jl)" local/bin/gap
