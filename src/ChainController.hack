/** test-chain is MIT licensed, see /LICENSE. */
namespace HTL\TestChain;

final class ChainController<T as Chain> {
  private function __construct(
    private (function()[defaults]: T) $createChain,
    private vec<(function()[defaults]: Awaitable<Chain>)> $chains,
  )[] {
  }

  public static function create(
    (function()[defaults]: Chain) $create_chain,
  )[]: this {
    return new static($create_chain, vec[]);
  }

  public function addTestGroup(
    (function(T)[defaults]: T) $registation,
  )[defaults]: this {
    $this->chains[] = async () ==> $registation(($this->createChain)());
    return $this;
  }

  public function addTestGroupAsync(
    (function(T)[defaults]: Awaitable<T>) $registation,
  )[defaults]: this {
    $this->chains[] = async () ==> await $registation(($this->createChain)());
    return $this;
  }

  public function withParallelGroupExecution()[]: this {
    return $this;
  }

  public function runAllAsync()[defaults]: Awaitable<void> {
    throw new \RuntimeException('not implemented runAllAsync');
  }
}
