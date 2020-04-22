#!/bin/bash
set -e
cd "$(julia meta/gappkgpath.jl)"/JuliaExperimental
# make test
gap --quitonbreak tst/testall.g
