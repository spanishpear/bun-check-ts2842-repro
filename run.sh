#!/usr/bin/env bash
# Runs each case through tsc 5.9.3, tsgo 7.0.2 and `bun check`, then compares to tsc.
# Env: BUN=path to bun (default: bun on PATH), TSRUST=path to a ts-rust tsgo binary (optional).
set -u
cd "$(dirname "$0")"
BUN=${BUN:-bun}
TSC=node_modules/typescript/bin/tsc
TSGO=node_modules/@typescript/native/bin/tsc
unset CLAUDECODE AGENT   # bun changes its output format when these are set

# Reduce a tool's output to the sorted list of TS error codes, or "ok".
codes() { grep -o 'error TS[0-9]*' | sed 's/error //' | sort -u | paste -sd, - ; }
norm() { local c; c=$(codes <<<"$1"); echo "${c:-ok}"; }

mkdir -p .tmp
echo "bun: $($BUN --revision)   tsc: $(node $TSC --version)   tsgo: $($TSGO --version)"
hdr=$(printf '%-30s %-9s %-9s %-9s %-9s' case expected tsc tsgo bun)
[ -n "${TSRUST:-}" ] && hdr+=$(printf ' %-9s' tsrust)
echo "$hdr result"

fail=0
for f in cases/*.ts; do
  name=$(basename "$f" .ts)
  cfg=.tmp/tsconfig.$name.json
  printf '{ "extends": "../tsconfig.json", "files": ["../%s"] }\n' "$f" > "$cfg"
  t=$(norm "$(node $TSC -p "$cfg" --pretty false 2>&1)")
  g=$(norm "$($TSGO -p "$cfg" --pretty false 2>&1)")
  b=$(norm "$($BUN check -p "$cfg" --no-pretty --threads 2 2>&1)")
  row=$(printf '%-30s %-9s %-9s %-9s %-9s' "$name" "$t" "$t" "$g" "$b")
  res=MATCH
  [ "$g" != "$t" ] && res=MISMATCH
  [ "$b" != "$t" ] && res=MISMATCH
  if [ -n "${TSRUST:-}" ]; then
    r=$(norm "$($TSRUST -p "$cfg" --pretty false 2>&1)")
    row+=$(printf ' %-9s' "$r")
    [ "$r" != "$t" ] && res=MISMATCH
  fi
  [ "$res" = MISMATCH ] && fail=1
  echo "$row $res"
done
exit $fail
