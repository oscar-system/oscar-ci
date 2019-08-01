#!/bin/bash
set -e
cd gap/pkg/GAPJulia/JuliaInterface
export TERM="dumb"
make check
