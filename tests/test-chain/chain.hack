/** test-chain is MIT licensed, see /LICENSE. */
namespace HTL\Project_376zb6OuUQX2\GeneratedTestChain;

use namespace HTL\TestChain;

async function tests_async(
)[defaults]: Awaitable<TestChain\ChainController<TestChain\Chain>> {
  return TestChain\ChainController::create(TestChain\TestChain::create<>)
    ->addTestGroup(\HTL\TestChain\SomeProject\my_test<>)
    ->addTestGroupAsync(\HTL\TestChain\SomeProject\my_test_async<>);
}
