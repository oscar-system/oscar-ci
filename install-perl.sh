#!/bin/sh
set -e

# Variables

PREFIX="$WORKSPACE/local"
PERL_VERSION=5.28.2
PERL_URL="https://www.cpan.org/src/5.0/perl-$PERL_VERSION.tar.gz"

# Already installed?

test -x "$PREFIX/bin/perl" && exit 0

# Download perl

mkdir -p "$WORKSPACE/tar"
curl -s -o "$WORKSPACE/tar/perl-$PERL_VERSION.tar.gz" "$PERL_URL"
mkdir -p "$WORKSPACE/perl"

# Build perl

pushd "$WORKSPACE/perl" >/dev/null
tar xzf ../tar/perl-$PERL_VERSION.tar.gz
pushd "perl-$PERL_VERSION" >/dev/null
./configure.gnu --prefix="$PREFIX"
make -j4
make install
popd >/dev/null
rm -rf "perl-$PERL_VERSION"
popd >/dev/null

# Install modules

export PATH="$PREFIX/bin:$PATH"

cpan -T JSON
cpan XML::LibXML XML::LibXSLT
cpan XML::Writer XML::Reader
cpan -T Term::ReadKey Term::ReadLine::Gnu
