#!/usr/bin/env bash

set -e

lib_name="duckdb"

echo "Compiling shared library into: bin/lib${lib_name}.dylib"
clang src/sql.c \
    -O3 -flto \
    -dynamiclib \
    -mtune=native \
    -o "bin/lib${lib_name}.dylib" \
    -undefined dynamic_lookup \
    -lduckdb -L"$(brew --prefix duckdb)/lib" -I"$(brew --prefix duckdb)/include"
