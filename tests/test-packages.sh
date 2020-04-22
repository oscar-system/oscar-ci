#!/bin/bash
set -e
PKGLOG="$WORKSPACE/.pkgerrors"
export TERM="dumb"
test -r "$PKGLOG" && cat "$PKGLOG"
# make test
julia/julia meta/packages-test.jl
