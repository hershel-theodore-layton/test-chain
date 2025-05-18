/** test-chain is MIT licensed, see /LICENSE. */
namespace HTL\Project_376zb6OuUQX2\GeneratedTestChain;

use namespace HH;
use namespace HH\Lib\{IO, Vec};

<<__DynamicallyCallable, __EntryPoint>>
async function run_tests_async()[defaults]: Awaitable<void> {
  $_argv = HH\global_get('argv') as vec<_> |> Vec\map($$, $x ==> $x as string);
  $tests = await tests_async();
  $result = await $tests
    ->withParallelGroupExecution()
    ->runAllAsync($tests->getBasicProgressReporter());

  $output = IO\request_output();
  if ($result->isSuccess()) {
    await $output->writeAllAsync("\nNo errors!\n");
    return;
  }

  exit(1);
}
