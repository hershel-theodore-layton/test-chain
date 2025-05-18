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

  public function test(
    string $name,
    (function()[defaults]: void) $test,
  )[]: this {
    return $this->testAsync($name, async ()[defaults] ==> $test());
  }

  public function testAsync(
    string $name,
    (function()[defaults]: Awaitable<void>) $test,
  )[]: this {
    invariant(
      !C\contains_key($this->tests, $name),
      'Test name "%s" is not unique in group "%s"',
      $name,
      $this->group,
    );

    $tests = $this->tests;
    $tests[$name] = $test;
    return new static($this->group, $tests);
  }

  public function testWith2Params<T1, T2>(
    string $name,
    (function()[defaults]: vec_or_dict<(T1, T2)>) $data_provider,
    (function(T1, T2)[defaults]: void) $test,
  )[]: this {
    return $this->dataProviderTest(
      $name,
      async ()[defaults] ==> $data_provider(),
      async ($args)[defaults] ==> $test(...$args),
    );
  }

  public function testWith2ParamsAsync<T1, T2>(
    string $name,
    (function()[defaults]: Awaitable<vec_or_dict<(T1, T2)>>) $data_provider,
    (function(T1, T2)[defaults]: Awaitable<void>) $test,
  )[]: this {
    return $this->dataProviderTest(
      $name,
      $data_provider,
      ($args)[defaults] ==> $test(...$args),
    );
  }

  public function testWith3Params<T1, T2, T3>(
    string $name,
    (function()[defaults]: vec_or_dict<(T1, T2, T3)>) $data_provider,
    (function(T1, T2, T3)[defaults]: void) $test,
  )[]: this {
    return $this->dataProviderTest(
      $name,
      async ()[defaults] ==> $data_provider(),
      async ($args)[defaults] ==> $test(...$args),
    );
  }

  public function testWith3ParamsAsync<T1, T2, T3>(
    string $name,
    (function()[defaults]: Awaitable<vec_or_dict<(T1, T2, T3)>>) $data_provider,
    (function(T1, T2, T3)[defaults]: Awaitable<void>) $test,
  )[]: this {
    return $this->dataProviderTest(
      $name,
      $data_provider,
      ($args)[defaults] ==> $test(...$args),
    );
  }

  public function testWith4Params<T1, T2, T3, T4>(
    string $name,
    (function()[defaults]: vec_or_dict<(T1, T2, T3, T4)>) $data_provider,
    (function(T1, T2, T3, T4)[defaults]: void) $test,
  )[]: this {
    return $this->dataProviderTest(
      $name,
      async ()[defaults] ==> $data_provider(),
      async ($args)[defaults] ==> $test(...$args),
    );
  }

  public function testWith4ParamsAsync<T1, T2, T3, T4>(
    string $name,
    (function()[defaults]: Awaitable<vec_or_dict<(T1, T2, T3, T4)>>)
      $data_provider,
    (function(T1, T2, T3, T4)[defaults]: Awaitable<void>) $test,
  )[]: this {
    return $this->dataProviderTest(
      $name,
      $data_provider,
      ($args)[defaults] ==> $test(...$args),
    );
  }

  public function testWith5Params<T1, T2, T3, T4, T5>(
    string $name,
    (function()[defaults]: vec_or_dict<(T1, T2, T3, T4, T5)>) $data_provider,
    (function(T1, T2, T3, T4, T5)[defaults]: void) $test,
  )[]: this {
    return $this->dataProviderTest(
      $name,
      async ()[defaults] ==> $data_provider(),
      async ($args)[defaults] ==> $test(...$args),
    );
  }

  public function testWith5ParamsAsync<T1, T2, T3, T4, T5>(
    string $name,
    (function()[defaults]: Awaitable<vec_or_dict<(T1, T2, T3, T4, T5)>>)
      $data_provider,
    (function(T1, T2, T3, T4, T5)[defaults]: Awaitable<void>) $test,
  )[]: this {
    return $this->dataProviderTest(
      $name,
      $data_provider,
      ($args)[defaults] ==> $test(...$args),
    );
  }

  public async function runTestsAsync(
    ChainController::TOptions $options,
  )[defaults]: Awaitable<TestGroupResult> {
    if ($options['parallel_tests_within_a_group']) {
      return await $this->runTestsInParallelAsync();
    }

    return await $this->runTestsInSeriesAsync();
  }

  private function dataProviderTest<T>(
    string $name,
    (function()[defaults]: Awaitable<vec_or_dict<T>>) $data_provider,
    (function(T)[defaults]: Awaitable<void>) $test_wrapper,
  )[]: this {
    return $this->testAsync($name, async ()[defaults] ==> {
      try {
        $data = await $data_provider();
      } catch (Throwable $e) {
        throw new InnerTestFailedException($name, 'data-provider', $e);
      }

      foreach ($data as $key => $params) {
        try {
          // This would be a very high degree of parallalism that is not
          // likely to be useful on large projects. We are still running
          // on a single thread after all.
          pragma('PhaLinters', 'fixme:dont_await_in_a_loop');
          await $test_wrapper($params);
        } catch (Throwable $e) {
          throw new InnerTestFailedException($name, (string)$key, $e);
        }
      }
    });
  }

  private async function runTestsInParallelAsync(
  )[defaults]: Awaitable<TestGroupResult> {
    return await Dict\map_with_key_async(
      $this->tests,
      async ($name, $t) ==> {
        try {
          await $t();
          return new TestSuccess($name);
        } catch (InnerTestFailedException $e) {
          return new TestFailure($e->getQualifiedName(), $e->getFailure());
        } catch (Throwable $e) {
          return new TestFailure($name, $e);
        }
      },
    )
      |> new TestGroupResult($this->group, vec($$));
  }

  private async function runTestsInSeriesAsync(
  )[defaults]: Awaitable<TestGroupResult> {
    $results = vec[];

    // Running in series, await in a loop, you get what you desired...
    foreach ($this->tests as $name => $test) {
      try {
        pragma('PhaLinters', 'fixme:dont_await_in_a_loop');
        await $test();
        $results[] = new TestSuccess($name);
      } catch (InnerTestFailedException $e) {
        $results[] = new TestFailure($e->getQualifiedName(), $e->getFailure());
      } catch (Throwable $e) {
        $results[] = new TestFailure($name, $e);
      }
    }

    return new TestGroupResult($this->group, $results);
  }
}
