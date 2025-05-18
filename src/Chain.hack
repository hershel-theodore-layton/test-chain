/** test-chain is MIT licensed, see /LICENSE. */
namespace HTL\TestChain;

interface Chain {
  public function group(string $group)[]: this;
  public function test(
    string $name,
    (function()[defaults]: void) $test,
  )[]: this;
  public function testAsync(
    string $name,
    (function()[defaults]: Awaitable<void>) $test,
  )[]: this;
  public function testWith2Params<T1, T2>(
    string $name,
    (function()[defaults]: vec_or_dict<(T1, T2)>) $data_provider,
    (function(T1, T2)[defaults]: void) $test,
  )[]: this;
  public function testWith2ParamsAsync<T1, T2>(
    string $name,
    (function()[defaults]: Awaitable<vec_or_dict<(T1, T2)>>) $data_provider,
    (function(T1, T2)[defaults]: Awaitable<void>) $test,
  )[]: this;
  public function testWith3Params<T1, T2, T3>(
    string $name,
    (function()[defaults]: vec_or_dict<(T1, T2, T3)>) $data_provider,
    (function(T1, T2, T3)[defaults]: void) $test,
  )[]: this;
  public function testWith3ParamsAsync<T1, T2, T3>(
    string $name,
    (function()[defaults]: Awaitable<vec_or_dict<(T1, T2, T3)>>) $data_provider,
    (function(T1, T2, T3)[defaults]: Awaitable<void>) $test,
  )[]: this;
  public function testWith4Params<T1, T2, T3, T4>(
    string $name,
    (function()[defaults]: vec_or_dict<(T1, T2, T3, T4)>) $data_provider,
    (function(T1, T2, T3, T4)[defaults]: void) $test,
  )[]: this;
  public function testWith4ParamsAsync<T1, T2, T3, T4>(
    string $name,
    (function()[defaults]: Awaitable<vec_or_dict<(T1, T2, T3, T4)>>)
      $data_provider,
    (function(T1, T2, T3, T4)[defaults]: Awaitable<void>) $test,
  )[]: this;
  public function testWith5Params<T1, T2, T3, T4, T5>(
    string $name,
    (function()[defaults]: vec_or_dict<(T1, T2, T3, T4, T5)>) $data_provider,
    (function(T1, T2, T3, T4, T5)[defaults]: void) $test,
  )[]: this;
  public function testWith5ParamsAsync<T1, T2, T3, T4, T5>(
    string $name,
    (function()[defaults]: Awaitable<vec_or_dict<(T1, T2, T3, T4, T5)>>)
      $data_provider,
    (function(T1, T2, T3, T4, T5)[defaults]: Awaitable<void>) $test,
  )[]: this;
  public function runTestsAsync(
    ChainController::TOptions $options,
  )[defaults]: Awaitable<TestGroupResult>;
}
