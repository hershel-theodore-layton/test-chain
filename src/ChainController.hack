/** test-chain is MIT licensed, see /LICENSE. */
namespace HTL\TestChain;

use namespace HH\Lib\{C, IO, Str, Vec};
use function HTL\Pragma\pragma;

final class ChainController<T as Chain> {
  const type TOptions = shape(
    'parallel_groups' => bool,
    'parallel_tests_within_a_group' => bool,
    /*_*/
  );
  private function __construct(
    private (function(
      (function(T)[defaults]: mixed),
    )[defaults]: T) $createChain,
    private vec<(function()[defaults]: Awaitable<Chain>)> $chainFuncs,
    private this::TOptions $options,
  )[] {
  }

  public static function create(
    (function((function(T)[defaults]: mixed))[defaults]: Chain) $create_chain,
  )[]: this {
    return new static($create_chain, vec[], shape(
      'parallel_groups' => false,
      'parallel_tests_within_a_group' => false,
    ));
  }

  public function addTestGroup(
    (function(T)[defaults]: T) $registation,
  )[defaults]: this {
    $this->chainFuncs[] = async () ==>
      $registation(($this->createChain)($registation));
    return $this;
  }

  public function addTestGroupAsync(
    (function(T)[defaults]: Awaitable<T>) $registation,
  )[defaults]: this {
    $this->chainFuncs[] = async () ==>
      await $registation(($this->createChain)($registation));
    return $this;
  }

  public function getBasicProgressReporter()[]: (function(
    TestGroupResult,
  )[defaults]: Awaitable<void>) {
    return async ($result)[defaults] ==> {
      $err = IO\request_error() ?? IO\request_output();

      if ($result->isSuccess()) {
        await $err->writeAllAsync('.');
        return;
      }

      await $err->writeAllAsync(Str\format(
        "\nF: %s (%d) tests failed\n",
        $result->getName(),
        C\count($result->getFailures()),
      ));
    };
  }

  public function withParallelGroupExecution()[]: this {
    $options = $this->options;
    $options['parallel_groups'] = true;
    return new static($this->createChain, $this->chainFuncs, $options);
  }

  public function withEntireTestSuiteParallism()[]: this {
    $options = $this->options;
    $options['parallel_groups'] = true;
    $options['parallel_tests_within_a_group'] = true;
    return new static($this->createChain, $this->chainFuncs, $options);
  }

  public async function runAllAsync(
    (function(TestGroupResult)[defaults]: Awaitable<void>) $callback,
  )[defaults]: Awaitable<vec<TestGroupResult>> {
    if ($this->options['parallel_groups']) {
      return await $this->runInParallelAsync($callback);
    }

    return await $this->runInSeriesAsync($callback);
  }

  public async function runInParallelAsync(
    (function(TestGroupResult)[defaults]: Awaitable<void>) $callback,
  )[defaults]: Awaitable<vec<TestGroupResult>> {
    return await Vec\map_async(
      $this->chainFuncs,
      async $f ==> {
        $chain = await $f();
        $result = await $chain->runTestsAsync($this->options);
        await $callback($result);
        return $result;
      },
    );
  }

  public async function runInSeriesAsync(
    (function(TestGroupResult)[defaults]: Awaitable<void>) $callback,
  )[defaults]: Awaitable<vec<TestGroupResult>> {
    $results = vec[];

    // Running in series, await in a loop, you get what you desired...
    foreach ($this->chainFuncs as $f) {
      pragma('PhaLinters', 'fixme:dont_await_in_a_loop');
      $chain = await $f();
      pragma('PhaLinters', 'fixme:dont_await_in_a_loop');
      $result = await $chain->runTestsAsync($this->options);
      pragma('PhaLinters', 'fixme:dont_await_in_a_loop');
      await $callback($result);
      $results[] = $result;
    }

    return $results;
  }
}
