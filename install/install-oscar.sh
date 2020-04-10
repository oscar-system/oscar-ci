#!/bin/bash
set -e
source meta/stdenv.sh
set -x
julia "meta/packages-${BUILDTYPE}.jl"
