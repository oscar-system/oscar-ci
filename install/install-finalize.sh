#!/bin/bash
set -e
source meta/stdenv.sh
julia -e 'include("meta/safepkg.jl"); SafePkg.precompile()'
