/** test-chain is MIT licensed, see /LICENSE. */
namespace HTL\TestChain;

<<__ConsistentConstruct>>
interface Invoker {
  public function __construct()[defaults];
  public function invokeAsync()[defaults]: Awaitable<void>;
}
