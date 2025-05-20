/** test-chain is MIT licensed, see /LICENSE. */
namespace HTL\Project_376zb6OuUQX2\GeneratedTestChain;

use namespace HTL\TestChain;

async function tests_async<T as TestChain\Chain>(
  TestChain\ChainController<T> $controller
)[defaults]: Awaitable<TestChain\ChainController<T>> {
  return $controller
    ->addTestGroup(\HTL\TestChain\SomeProject\my_test<>)
    ->addTestGroupAsync(\HTL\TestChain\SomeProject\my_test_async<>)
    ->addTestGroup(\HTL\TestChain\SomeProject\passing_test<>);
}
