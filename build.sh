#!/usr/bin/env bash

set -e

lib_name="${DENO_DUCKDB_LIBNAME:-duckdb-deno}"
lib_output="bin/lib${lib_name}.dylib"

echo "Compiling shared library into: ${lib_output}"
clang src/sql.c \
    -O3 -flto \
    -dynamiclib \
    -mtune=native \
    -o "${lib_output}" \
    -undefined dynamic_lookup \
    -lduckdb -L"$(brew --prefix duckdb)/lib" -I"$(brew --prefix duckdb)/include"
