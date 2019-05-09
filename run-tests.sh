#!/bin/sh
for testfile in meta/tests/*.sh; do
  sh $testfile
done
