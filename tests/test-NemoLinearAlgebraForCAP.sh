#!/bin/bash
set -e
cd "$(julia meta/gappkgpath.jl)"/NemoLinearAlgebraForCAP
make test

