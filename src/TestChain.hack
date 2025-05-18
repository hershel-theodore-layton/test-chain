/** test-chain is MIT licensed, see /LICENSE. */
namespace HTL\TestChain;

use namespace HH\Lib\C;
use type FunctionCredential;

final class TestChain implements Chain {
  private function __construct(
    private string $group,
    private dict<string, (function()[defaults]: Awaitable<void>)> $tests,
  )[] {}

  public static function create()[]: this {
    return new TestChain('unnamed group', dict[]);
  }

  public function group(FunctionCredential $group)[]: this {
    return new static($group->getFunctionName(), $this->tests);
  }

  public function test(
    string $name,
    (function()[defaults]: void) $test,
  )[]: this {
    invariant(
      !C\contains_key($this->tests, $name),
      'Test name "%s" is not unique in group "%s"',
      $name,
      $this->group,
    );

    $tests = $this->tests;
    $tests[$name] = async ()[defaults] ==> $test();
    return new static($this->group, $tests);
  }
}
