#!/bin/bash
PKGDIR="$(julia meta/gappkgpath.jl)"
rm -f "$PKGDIR"/`basename $1`
ln -s "$1" "$PKGDIR/"
