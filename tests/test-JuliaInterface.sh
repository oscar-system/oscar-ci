#!/bin/bash
set -e
cd gap/pkg/JuliaInterface
export TERM="dumb"
# make test
gap tst/testall.g
