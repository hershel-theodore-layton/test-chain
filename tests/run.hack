/** test-chain is MIT licensed, see /LICENSE. */
namespace HTL\Project_376zb6OuUQX2\GeneratedTestChain;

use namespace HH;
use namespace HH\Lib\Vec;

<<__EntryPoint>>
async function run_tests_async()[defaults]: Awaitable<void> {
  $_argv = HH\global_get('argv') as vec<_> |> Vec\map($$, $x ==> $x as string);
  $tests = await tests_async();
  $results = await $tests
    ->withParallelGroupExecution()
    ->runAllAsync($tests->getBasicProgressReporter());
}
