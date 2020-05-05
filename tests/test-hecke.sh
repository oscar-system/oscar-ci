#!/bin/bash
set -e
source meta/stdenv.sh
linebuf julia -e 'using Pkg; Pkg.test("Hecke");'
