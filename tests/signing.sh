#!/bin/sh
# test-chain is MIT licensed, see /LICENSE.
set -eu

snapshot=$(mktemp -d)
trap 'cp "$snapshot/chain.hack" tests/test-chain/chain.hack; rm -rf "$snapshot"' EXIT
cp tests/test-chain/chain.hack "$snapshot/chain.hack"
cp tests/test-chain/run.hack "$snapshot/run.hack"
cp tests/test-chain/config.json "$snapshot/config.json"
mkdir -p .var

run_cli() {
  hhvm -dhhvm.autoload.enabled=true -dhhvm.autoload.db.path=.var/signing-facts.db bin/test-chain.hack "$@"
}

# Generation must preserve the previously formatted, signed bytes.
run_cli
cmp "$snapshot/chain.hack" tests/test-chain/chain.hack
run_cli --ci

# A stale chain must fail CI without writing any generated destination.
printf '\n// Deliberately stale signing probe.\n' >> tests/test-chain/chain.hack
cp tests/test-chain/chain.hack "$snapshot/stale.hack"
if run_cli --ci > "$snapshot/ci.log" 2>&1; then
  echo 'Expected stale generated code to fail CI.' >&2
  exit 1
fi
grep -q 'Codegen out of date' "$snapshot/ci.log"
cmp "$snapshot/stale.hack" tests/test-chain/chain.hack
cmp "$snapshot/run.hack" tests/test-chain/run.hack
cmp "$snapshot/config.json" tests/test-chain/config.json
