# bun check reports TS2842 where tsc and tsgo report nothing

`bun check` reports a false TS2842 ("'X' is an unused renaming of 'a'") when a destructured parameter in a function type renames a property to the name of one of that signature's type parameters.

One-line repro:

```ts
export type Fn = <X>({ a: X }: { a: X }) => void;
```

tsc 5.9.3 and tsgo 7.0.2 report nothing. `bun check` reports:

```
error TS2842: 'X' is an unused renaming of 'a'. Did you intend to use it as a type annotation?
```

## Reproduce

```sh
bun install && ./run.sh
```

`run.sh` runs every file in `cases/` through tsc, tsgo and `bun check --threads 2`. It compares each tool to tsc and exits nonzero on any mismatch. Set `BUN=/path/to/bun` to pick a binary, and `TSRUST=/path/to/tsgo` to add a ts-rust column.

## Output

Run on bun 1.4.3-canary.1+5749c3129 (newest canary on 2026-10-08), tsc 5.9.3, tsgo 7.0.2:

```
case                           expected  tsc       tsgo      bun       tsrust    result
1-computed-key-generic         ok        ok        ok        TS2842    ok        MISMATCH
2-plain-key-generic            ok        ok        ok        TS2842    ok        MISMATCH
3-used-in-return               ok        ok        ok        TS2842    ok        MISMATCH
4-control-non-generic          TS2842    TS2842    TS2842    TS2842    TS2842    MATCH
5-control-unrelated-typeparam  TS2842    TS2842    TS2842    TS2842    TS2842    MATCH
```

The same three cases also fail on 1.4.3-canary.1+bd599f5af. Cases 4 and 5 are controls. In both, the renamed binding is not a type parameter, and every tool reports TS2842.

Expected: cases 1 to 3 print `ok` for bun. Actual: bun reports TS2842.

## Why tsc is the reference

`bun check` states parity with tsc 7. tsgo 7.0.2 is tsc 7, and it gives the same results as tsc 5.9.3 on every case here. The difference comes from bun's checker.

## Versions

- bun 1.4.3-canary.1+5749c3129 and 1.4.3-canary.1+bd599f5af
- typescript 5.9.3
- typescript 7.0.2 (installed as `@typescript/native`, the tsgo binary)

`bunfig.toml` is git-ignored here. If your default npm registry is private, point `[install] registry` at https://registry.npmjs.org/.
