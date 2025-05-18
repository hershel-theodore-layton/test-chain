/** test-chain is MIT licensed, see /LICENSE. */
namespace HTL\TestChain;

interface Chain {
  public function group(string $group)[]: this;
  public function test(
    string $name,
    (function()[defaults]: void) $test,
  )[]: this;
  public function runTestsAsync(
    ChainController::TOptions $options,
  )[defaults]: Awaitable<TestGroupResult>;
}
