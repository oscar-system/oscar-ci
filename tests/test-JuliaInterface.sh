#!/bin/bash
set -e
gap --quitonbreak -c 'Read(Filename(DirectoriesPackageLibrary("JuliaInterface", "tst"), "testall.g"));'
