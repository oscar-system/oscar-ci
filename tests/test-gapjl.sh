#!/bin/sh
set -e
julia/julia -e 'using Pkg; Pkg.test("GAP");'
