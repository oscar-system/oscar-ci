#!/bin/bash
set -e
gap --quitonbreak -c 'Read(Filename(DirectoriesPackageLibrary("JuliaExperimental", "tst"), "testall.g"));'
