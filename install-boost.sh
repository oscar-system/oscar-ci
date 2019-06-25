#!/bin/sh
set -e

# Variables

PREFIX="$WORKSPACE/local"
BOOST_VERSION="1.70.0"
eval "$(awk '{
  gsub("[.]", "_");
  print "BOOST_VPATH=" $0;
}' <<<"$BOOST_VERSION")"

BOOST_URL="https://dl.bintray.com/boostorg/release/$BOOST_VERSION/source/boost_$BOOST_VPATH.tar.gz"

# Already installed?

BOOST_TEST_LIB="lib/libboost_system.a"

test -f "$PREFIX/$BOOST_TEST_LIB" && exit 0

# Download Boost

mkdir -p "$WORKSPACE/tar"
wget --quiet -O "$WORKSPACE/tar/boost_$BOOST_VPATH.tar.gz" "$BOOST_URL"
mkdir -p "$WORKSPACE/boost"

# Build Boost

pushd "$WORKSPACE/boost" >/dev/null
tar xzf "../tar/boost_$BOOST_VPATH.tar.gz"
pushd "boost_$BOOST_VPATH" >/dev/null
sh bootstrap.sh --prefix="$PREFIX"
./b2 --prefix="$PREFIX" -j4 -d0
./b2 --prefix="$PREFIX" -j4 -d0 headers
./b2 --prefix="$PREFIX" install
popd >/dev/null
rm -rf "boost_$BOOST_VPATH"
popd >/dev/null

