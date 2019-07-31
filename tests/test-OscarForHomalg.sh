#!/bin/bash
set -e
cd gap/pkg/OscarForHomalg
export TERM="dumb"
# make test
gap makedoc.g
gap tst/testall.g
