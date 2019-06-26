#!/bin/bash
mkdir -p logs
(
cd gap
echo "=== Testing GAP @ $(date) ==="
./gap tst/testinstall.g
echo "=== Status: $? ==="
) 2>&1 | tee logs/gap.log
