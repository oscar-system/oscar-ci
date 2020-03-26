#!/bin/bash
set -e
cd "$(julia meta/gappkgpath.jl)"/JuliaInterface
export TERM="dumb"
# make test
gap --quitonbreak tst/testall.g
