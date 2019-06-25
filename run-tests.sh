#!/bin/sh
for testfile in meta/tests/*; do
  test -x "$testfile" && "./$testfile"
done
