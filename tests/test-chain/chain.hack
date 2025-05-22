/** test-chain is MIT licensed, see /LICENSE. */
namespace HTL\Project_376zb6OuUQX2\GeneratedTestChain;

use namespace HTL\TestChain;

async function tests_async(
  TestChain\ChainController<\HTL\TestChain\Chain> $controller
)[defaults]: Awaitable<TestChain\ChainController<\HTL\TestChain\Chain>> {
  return $controller
    ->addTestGroup(\HTL\TestChain\SomeProject\my_test<>)
    ->addTestGroupAsync(\HTL\TestChain\SomeProject\my_test_async<>)
    ->addTestGroup(\HTL\TestChain\SomeProject\passing_test<>);
}
