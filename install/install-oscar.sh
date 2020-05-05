#!/bin/bash
set -e
source meta/stdenv.sh
# set -x
# touch .pkgstatus
# find . -maxdepth 2 -name Project.toml -type f -print0 | \
# 	xargs -0 shasum >.pkgstatus.tmp
# if ! cmp .pkgstatus .pkgstatus.tmp >/dev/null 2>&1; then
#   rm -rf jenv .pkgstatus
#   mv -f .pkgstatus.tmp .pkgstatus
# fi
rm -rf jenv
julia "meta/install/install-oscar.jl"
