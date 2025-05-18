/** test-chain is MIT licensed, see /LICENSE. */
namespace HTL\TestChain;

final class ChainController<T as Chain> {
  const type TOptions = shape(
    'parallel' => bool,
    /*_*/
  );
  private function __construct(
    private (function(
      (function(T)[defaults]: mixed),
    )[defaults]: T) $createChain,
    private vec<(function()[defaults]: Awaitable<Chain>)> $chains,
    private this::TOptions $options,
  )[] {
  }

  public static function create(
    (function((function(T)[defaults]: mixed))[defaults]: Chain) $create_chain,
  )[]: this {
    return new static($create_chain, vec[], shape('parallel' => false));
  }

  public function addTestGroup(
    (function(T)[defaults]: T) $registation,
  )[defaults]: this {
    $this->chains[] = async () ==>
      $registation(($this->createChain)($registation));
    return $this;
  }

  public function addTestGroupAsync(
    (function(T)[defaults]: Awaitable<T>) $registation,
  )[defaults]: this {
    $this->chains[] = async () ==>
      await $registation(($this->createChain)($registation));
    return $this;
  }

  public function withParallelGroupExecution()[]: this {
    $options = $this->options;
    $options['parallel'] = true;
    return new static($this->createChain, $this->chains, $options);
  }

  public function runAllAsync()[defaults]: Awaitable<void> {
    throw new \RuntimeException('not implemented runAllAsync');
  }
}
