/** test-chain is MIT licensed, see /LICENSE. */
namespace HTL\TestChain\SomeProject;

use namespace HH\Asio;
use namespace HTL\TestChain;

<<TestChain\Discover>>
function my_test(TestChain\Chain $chain)[]: TestChain\Chain {
  return $chain->group(__FUNCTION__)
    ->test('addition', () ==> {
      throw new \RuntimeException('not implementetd');
    });
}

<<TestChain\Discover>>
async function my_test_async(
  TestChain\Chain $chain,
)[defaults]: Awaitable<TestChain\Chain> {
  // Here you can write code to execute before the first test.
  await Asio\later();

  return $chain->group(__FUNCTION__)
    ->test('subtraction', () ==> {
      throw new \RuntimeException('not implemented async');
    });
}

<<TestChain\Discover>>
function passing_test(TestChain\Chain $chain)[]: TestChain\Chain {
  return $chain->group(__FUNCTION__)
    ->test('multiplication', () ==> {
      if (2 * 3 !== 6) {
        throw new \LogicException('2 * 3 !== 6');
      }
    })
    ->testWith3ParamsAsync(
      'division',
      async () ==> vec[
        tuple(8, 2, 4),
        tuple(12, 3, 4),
      ],
      async ($a, $b, $expected) ==> {
        if ($a / $b !== $expected) {
          throw new \LogicException('math broke');
        }
      },
    );
}

function not_a_test_function()[]: void {}
