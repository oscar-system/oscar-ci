#!/bin/bash
set -e
cd "$(julia meta/gappkgpath.jl)"/NemoLinearAlgebraForCAP
export TERM="dumb"
make test

