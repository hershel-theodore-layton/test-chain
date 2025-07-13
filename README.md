# Test Chain

_Inferred types for your tests, just append._

This package was written to replace [HackTest](https://github.com/hhvm/hacktest).

This package is enjoyed best with an assertion library, such as [expect](https://github.com/hershel-theodore-layton/expect).

## Usage

Create a `tests/` directory at the root of your project (next to `vendor/`).
This package ships with a `bin/test-chain` script. Do not pass any command line 
arguments to this script.

This script will create a json file at `tests/test-chain/config.json`. The
defaults will likely suffice, but you can change the configuration to your
liking. The `tests/run.hack` file template is meant for you to customize, and
allows you to do setup work before running the tests.

Let's add your first test. Create `tests/math_test.hack` with this content.

```HACK
namespace YourNamespace;

use namespace HTL\TestChain;

<<TestChain\Discover>>
function my_test(TestChain\Chain $chain)[]: TestChain\Chain {
  return $chain->group(__FUNCTION__)
    ->test('addition', () ==> {
      throw new \RuntimeException('not implemented');
    });
}
```

You can discover your tests using `vendor/bin/test-chain`. You can run your
tests using `hhvm tests/run.hack`. You can combine these steps with
`vendor/bin/test-chain --run`. You should see this output.

```
(0001 / 0001) Fail: YourNamespace\my_test (1 tests)
  - addition: not implemented
---

Tests failed!
```

It is common to want to execute the same test with multiple values. This is
called a data-provider test. Here is an example of a such a test:

```HACK
<<TestChain\Discover>>
function passing_test(TestChain\Chain $chain)[]: TestChain\Chain {
  return $chain->group(__FUNCTION__)
    ->testWith3Params(
      'division',
      () ==> vec[
        tuple(8, 2, 4),
        tuple(12, 3, 4),
      ],
      ($a, $b, $expected) ==> {
        if ($a / $b !== $expected) {
          throw new \LogicException('math broke');
        }
      },
    );
}
```

## Running in CI

When running in CI, you don't want to suddenly discover new tests. If that
were allowed, the tests you see in git and what runs in CI wouldn't be the same.
By passing `--ci` to `vendor/bin/test-chain`, you assert the chain.hack file
was correct and invoke the tests in the same way as with `--run`.

## Performance on small test suites

By default hhvm will try to jit your tests as you run them, unless overriden in
your global hhvm configuration. This is not helpful on most small test suites.
`vendor/bin/test-chain-no-jit` behaves exactly like `vendor/bin/test-chain`, but
invokes hhvm without the jit. This can shave of a second of your test execution
time. It will run a test suite with a handful of fast tests in 0.5 seconds
instead of 1.5 seconds.

If you want to run your tests in 0.05 seconds, you can host your tests as a
web server. `hhvm -m server -p <%port%>` and curl
`http://localhost:<%port%>/tests/test-chain/run.hack`. This will not crawl your
tests directory for new test functions. Chained tests on existing functions
will be found and run, but new `<<TestChain\Discover>>` functions must be
explicitly crawled for with the CLI script.

## Upgrades and compatibility

When the codegen for `chain.hack` changes, all invocations with `--ci` will fail.
Running without `--ci` will regenerate this file and further invocations of
`--ci` will not fail. If a change to `chain.hack` makes the call in `run.hack`
you can regen it with `--update`. Your custom change will have to be reapplied.
If none of that  works, `--reset` will treat your project as a brand new
project, keeping the license comment and the namespace the same for convenience.

These breakages in codegen will **not** require a major version bump.
