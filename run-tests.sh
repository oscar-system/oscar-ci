#!/bin/bash
set -e
mkdir -p logs
source meta/stdenv.sh
python3 meta/run-tests.py
