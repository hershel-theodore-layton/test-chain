/** test-chain is MIT licensed, see /LICENSE. */
namespace HTL\TestChain;

use namespace HH\Lib\{C, Dict};
use type Throwable;
use function HTL\Pragma\pragma;

final class TestChain implements Chain {
  private function __construct(
    private string $group,
    private dict<string, (function()[defaults]: Awaitable<void>)> $tests,
  )[] {}

  public static function create(
    (function(Chain)[defaults]: mixed) $_registration,
  )[]: this {
    return new TestChain('unnamed group', dict[]);
  }

  public function group(string $group)[]: this {
    return new static($group, $this->tests);
  }

  public async function runTestsAsync(
    ChainController::TOptions $options,
  )[defaults]: Awaitable<TestGroupResult> {
    if ($options['parallel_tests_within_a_group']) {
      return await $this->runTestsInParallelAsync();
    }

    return await $this->runTestsInSeriesAsync();
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

  public async function runTestsInParallelAsync(
  )[defaults]: Awaitable<TestGroupResult> {
    return await Dict\map_with_key_async(
      $this->tests,
      async ($name, $t) ==> {
        try {
          await $t();
          return new TestSuccess($name);
        } catch (Throwable $e) {
          return new TestFailure($name, $e);
        }
      },
    )
      |> new TestGroupResult($this->group, vec($$));
  }

  public async function runTestsInSeriesAsync(
  )[defaults]: Awaitable<TestGroupResult> {
    $results = vec[];

    foreach ($this->tests as $name => $test) {
      try {
        pragma('PhaLinters', 'fixme:dont_await_in_a_loop');
        await $test();
        $results[] = new TestSuccess($name);
      } catch (Throwable $e) {
        $results[] = new TestFailure($name, $e);
      }
    }

    return new TestGroupResult($this->group, $results);
  }
}
