#!/bin/bash
set -e
export TERM="dumb"
# make test
julia/julia meta/packages-test.jl
