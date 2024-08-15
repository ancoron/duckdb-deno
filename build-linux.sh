#!/usr/bin/env bash

set -e

duckdb_version="${DUCKDB_VERSION:-1.0.0}"
lib_name="${DENO_DUCKDB_LIBNAME:-duckdb-deno}"

host_arch="$(uname -m)"
[ "${host_arch}" != "x86_64" ] || host_arch="amd64"

cache_dir=.local
lib_archive="${cache_dir}/lib.zip"

lib_dir="${DUCKDB_LIB_DIR}"
[ -d "${lib_dir}" ] || lib_dir="${cache_dir}/lib"

lib_path="${DUCKDB_SO_PATH}"
[ -f "${lib_path}" ] || lib_path="${lib_dir}/libduckdb.so"

mkdir -p bin

if [ ! -f "${lib_path}" ]; then
    mkdir -p "${cache_dir}" "${lib_dir}"

    if [ ! -f "${lib_archive}" ]; then
        echo "Downloading DuckDB library version ${duckdb_version} (${host_arch})"
        wget -q -O "${lib_archive}" "https://github.com/duckdb/duckdb/releases/download/v${duckdb_version}/libduckdb-linux-${host_arch}.zip"
    fi

    unzip -q -d "${lib_dir}" "${lib_archive}"
fi

echo "Compiling shared library into: bin/lib${lib_name}.so"
clang src/sql.c \
    -O3 -flto \
    -shared \
    -mtune=native \
    -o "bin/lib${lib_name}.so" \
    -lduckdb -I"${lib_dir}"/ -L"${lib_dir}"/

cp "${lib_path}" bin/
