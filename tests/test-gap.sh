#!/bin/bash
set -e
# Some GAP string tests break with a different encoding.
export LC_ALL=en_US.UTF-8
export LC_CTYPE="$LC_ALL"
gap --quitonbreak -c 'ReadGapRoot("tst/testinstall.g");'
