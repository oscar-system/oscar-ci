#!/bin/bash
set -e
cd "$(julia meta/gappkgpath.jl)"/OscarForHomalg
export TERM="dumb"
# make test
gap --quitonbreak makedoc.g
gap --quitonbreak tst/testall.g
