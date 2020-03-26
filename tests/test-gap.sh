#!/bin/bash
set -e
export TERM=dumb
gap --quitonbreak -c 'ReadGapRoot("tst/testinstall.g");'
