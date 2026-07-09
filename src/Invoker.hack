/** test-chain is MIT licensed, see /LICENSE. */
namespace HTL\TestChain;

interface Invoker {
  public function invokeAsync()[defaults]: Awaitable<void>;
}
