#!/bin/bash
set -e
cd "$(julia meta/gappkgpath.jl)"/JuliaInterface
# make test
gap --quitonbreak tst/testall.g
