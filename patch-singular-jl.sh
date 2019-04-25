#!/bin/sh
SINGULAR_JL="$WORKSPACE/Singular.jl"
git -C "$SINGULAR_JL" show HEAD:deps/build.jl | \
awk '{ sub("https://github[.]com/Singular/Sources[.]git",
  ENVIRON["WORKSPACE"] "/singular"); print $0; }' | \
cat > $SINGULAR_JL/deps/build.jl
