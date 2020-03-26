#!/bin/bash
set -e
cd "$(julia meta/gappkgpath.jl)"/JuliaExperimental
export TERM="dumb"
# make test
gap --quitonbreak tst/testall.g
