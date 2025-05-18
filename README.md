# Test Chain

_Inferred types for your tests, just append._

This package was written to replace [HackTest](https://github.com/hhvm/hacktest).

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
function test_math_test(TestChain\Chain $chain)[]: TestChain\Chain {
  return $chain->group(__FUNCTION_CREDENTIAL__)
    ->test('addition', () ==> {
      throw new \RuntimeException('not implemented');
    });
}
```

You can discover your tests using `vendor/bin/test-chain`. You can run your
tests using `hhvm tests/run.hack`. You can combine these step with
`vendor/bin/test-chain --run`. You should see this output.

TODO: continue
