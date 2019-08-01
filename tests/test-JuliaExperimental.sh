#!/bin/bash
set -e
cd gap/pkg/GAPJulia/JuliaExperimental
export TERM="dumb"
make check
