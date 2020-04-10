#!/bin/bash
set -e
source meta/stdenv.sh
BASEDIR="$(realpath "$(dirname "$0")")"
"$BASEDIR/install-gap-pkg.sh" NemoLinearAlgebraForCAP
