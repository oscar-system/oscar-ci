#!/bin/bash
rm -f "$WORKSPACE/gap/pkg/`basename $1`"
ln -s "$1" "$WORKSPACE/gap/pkg/"
