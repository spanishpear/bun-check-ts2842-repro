# `bun check` reports TS2842 for a destructured parameter whose rename matches a type parameter

`bun check` reports TS2842 for `export type Fn = <X>({ a: X }: { a: X }) => void;`. tsc 5.9.3 and tsgo 7.0.2 report nothing.

## Repro

```ts
export type Fn = <X>({ a: X }: { a: X }) => void;
```

tsconfig: `strict`, `noEmit`, `target es2022`, `module esnext`, `moduleResolution bundler`, `skipLibCheck`.

```sh
bun check --threads 2
```

```
error TS2842: 'X' is an unused renaming of 'a'. Did you intend to use it as a type annotation?
```

The attached repo has a `run.sh` that runs every case through tsc, tsgo and bun. Run `bun install && ./run.sh`.

## Cases

Output of `run.sh` on bun 1.4.3-canary.1+5749c3129:

| Case | Source | tsc 5.9.3 | tsgo 7.0.2 | bun |
| --- | --- | --- | --- | --- |
| 1 | `export const K = { A: 'a' } as const; export type Fn = <X>({ [K.A]: X }: { [K.A]: X }) => void;` | ok | ok | TS2842 |
| 2 | `export type Fn = <X>({ a: X }: { a: X }) => void;` | ok | ok | TS2842 |
| 3 | `export type Fn = <X>({ a: X }: { a: X }) => X;` | ok | ok | TS2842 |
| 4 (control) | `export type Fn = ({ a: string }: { a: string }) => void;` | TS2842 | TS2842 | TS2842 |
| 5 (control) | `export type Fn = <T>({ a: X }: { a: T }) => void;` | TS2842 | TS2842 | TS2842 |

The ts-rust build of typescript-go matches tsc on all five cases. The controls show that all tools agree when the renamed name is not a type parameter of the signature.

## Versions

- bun 1.4.3-canary.1+5749c3129 (newest canary on 2026-10-08), reproduces
- bun 1.4.3-canary.1+bd599f5af, reproduces
- tsc 5.9.3
- tsgo 7.0.2 (`typescript@7.0.2` on npm)

## Expected

No diagnostic for cases 1 to 3, as in tsc and tsgo. `bun check` states parity with tsc 7, and tsgo 7.0.2 agrees with tsc 5.9.3 here.

## Actual

TS2842 on the renamed binding in cases 1 to 3. In a large monorepo this produced 2 false errors, from a generic function type declaring `{ [Enum.START]: StartCb, [Enum.STOP]: StopCb }?: {...}`.

## Hypothesis

I have not read bun's source, so this is a guess. In tsc, the name `X` in `{ a: X }` resolves to the type parameter `X`, and cases 1 to 3 pass. In case 5, where no `X` is in scope, the same code is an error. bun's check for an unused renaming probably does not take the type reference to a same-named type parameter into account, so it treats the binding as unreferenced. A fix would resolve the name as tsc does before reporting.

## Related

- oven-sh/bun#44686: another `bun check` divergence from TS 7.0.2 (missing TS2345). Same area, not a duplicate.
- oven-sh/bun#44719, #44706, #44660: other `bun check` fidelity reports. Not duplicates.
- microsoft/TypeScript#50060: origin of TS2842 in TS 4.8. It flags renames in signatures that have no body, which is the case here.
- A search of oven-sh/bun and microsoft/typescript-go for "TS2842" and "unused renaming" found no matching issue. typescript-go has been archived since 2026-09-01.
