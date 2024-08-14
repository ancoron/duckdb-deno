<h1 align=center>x/duckdb</h1>
<div align=center>blazing fast <a href=https://duckdb.org>duckdb</a> bindings for deno</div>

<br />

## performance

- 2-4x faster than Bun.
- 10x faster than Node.

<details><summary>View source</summary>

```typescript
import { open } from "jsr:@divy/duckdb@0.2";

const db = open("/tmp/test.db");
const connection = db.connect();

const q = "select i, i as a from generate_series(1, 100000) s(i)";

const p = connection.prepare(q);
console.log("benchmarking query: " + q);

bench("duckdb", () => {
  p.query();
});

await run({ percentiles: false });

connection.close();
db.close();
```

</details>
<summary>

```
# Deno canary

benchmarking query: select i, i as a from generate_series(1, 100000) s(i)
cpu: Apple M1
runtime: deno 1.24.0 (aarch64-apple-darwin)

benchmark      time (avg)             (min … max)
-------------------------------------------------
duckdb       4.66 ms/iter     (4.26 ms … 7.47 ms)
```

```
# Bun
benchmarking query: select i, i as a from generate_series(1, 100000) s(i)
cpu: Apple M1
runtime: bun 0.1.4 (arm64-darwin)

benchmark      time (avg)             (min … max)
-------------------------------------------------
duckdb       8.69 ms/iter     (6.26 ms … 11.4 ms)
```

<details><summary>View JIT benchmarks</summary>

```typescript
const db = open(":memory:");
const connection = db.connect(db);
const q = "select i, i as a from generate_series(1, 100000) s(i)";

const p = connection.prepare(q);
console.log("benchmarking query: " + q);

group("query", () => {
  bench("jit query()", () => p.query());
  bench("query()", () => connection.query(q));
});

group("stream", () => {
  bench("jit stream()", () => {
    for (const x of p.stream()) x;
  });

  bench("stream()", () => {
    for (const x of connection.stream(q)) x;
  });
});
```

```
# Deno canary

benchmarking query: select i, i as a from generate_series(1, 100000) s(i)
cpu: Apple M1
runtime: deno 1.24.0 (aarch64-apple-darwin)

benchmark         time (avg)             (min … max)
----------------------------------------------------
query
----------------------------------------------------
jit query()     4.79 ms/iter    (4.31 ms … 12.06 ms)
query()         8.26 ms/iter    (7.54 ms … 16.44 ms)

summary for query
  jit query()
   1.72x faster than query()

stream
----------------------------------------------------
jit stream()    9.96 ms/iter    (9.84 ms … 10.18 ms)
stream()       10.97 ms/iter   (10.82 ms … 11.35 ms)

summary for stream
  jit stream()
   1.1x faster than stream()
```

```
# Bun

benchmarking query: select i, i as a from generate_series(1, 100000) s(i)
cpu: Apple M1
runtime: bun 0.1.4 (arm64-darwin)

benchmark         time (avg)             (min … max)
----------------------------------------------------
query
----------------------------------------------------
jit query()     8.61 ms/iter    (7.54 ms … 10.43 ms)
query()         18.5 ms/iter   (17.16 ms … 20.34 ms)

summary for query
  jit query()
   2.15x faster than query()

stream
----------------------------------------------------
jit stream()   16.36 ms/iter   (15.55 ms … 17.79 ms)
stream()       21.44 ms/iter   (21.02 ms … 23.18 ms)

summary for stream
  jit stream()
   1.31x faster than stream()
```

</details>
<summary>

## examples

```typescript
import { open } from "https://deno.land/x/duckdb/mod.ts";

const db = open("./example.db");
// or const db = open(':memory:');

const connection = db.connect();

connection.query("select 1 as number"); // -> [{ number: 1 }]

for (const row of connection.stream("select 42 as number")) {
  row; // -> { number: 42 }
}

const prepared = connection.prepare(
  "select ?::INTEGER as number, ?::VARCHAR as text",
);

prepared.query(1337, "foo"); // -> [{ number: 1337, text: 'foo' }]
prepared.query(null, "bar"); // -> [{ number: null, text: 'bar' }]

connection.close();
db.close();
```

## Development

Since we need the official DuckDB shared library and header file for building
the FFI bindings, some helper scripts are available to initialize everything and
compile our own library (in `src/` directory) using the Clang LLVM compiler
tool.

### Linux

```bash
./build-linux.sh
```

...or alternatively:

```bash
deno task lib-linux
```

This puts everything needed into directory `bin/`, so that we can use it for
telling the Deno runtime where to look when trying to find our shared library as
well as the one from DuckDB.

You can add the newly populated directory to the library search path, so that
you won't get weird errors later:

```bash
export LD_LIBRARY_PATH=bin
```

#### Execute Tests

The best way to verify that your setup is working properly is to run the tests
as follows:

```bash
deno task test
```

If you happen to see an error like this you did not adjust your library search
path with `LD_LIBRARY_PATH`:

```
./mod_test.ts (uncaught error)
error: (in promise) Error: Could not open library: Could not open library: libduckdb-deno.so: cannot open shared object file: No such file or directory
const { symbols: duck } = Deno.dlopen(get_lib(), {
                               ^
    at new DynamicLibrary (ext:deno_ffi/00_ffi.js:454:42)
    at Object.dlopen (ext:deno_ffi/00_ffi.js:558:10)
    at file:///home/ancoron/dev/duckdb-deno/lib.js:39:32
```

## Credits

Thanks to the original author of `@evan/duckdb`
[@evanwashere](https://github.com/evanwashere) for most of the implementation
that has been reused in this module.

## License

Modifications are licensed under MIT © [Divy](https://github.com/littledivy)

Original (bun version):

Apache-2.0 © [Evan](https://github.com/evanwashere)
