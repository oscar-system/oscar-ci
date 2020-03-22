#!/bin/bash
set -e
cd gap/pkg/JuliaExperimental
export TERM="dumb"
# make test
gap tst/testall.g
