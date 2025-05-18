/** test-chain is MIT licensed, see /LICENSE. */
namespace HTL\TestChain;

use type FunctionCredential;

interface Chain {
  public function group(FunctionCredential $function_credential)[]: this;
  public function test(
    string $name,
    (function()[defaults]: void) $test,
  )[]: this;
  public function runTestsAsync(
    ChainController::TOptions $options,
  )[defaults]: Awaitable<TestGroupResult>;
}
