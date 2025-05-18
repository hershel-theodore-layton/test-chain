/** test-chain is MIT licensed, see /LICENSE. */
namespace HTL\TestChain;

use type RuntimeException, Throwable;

final class InnerTestFailedException extends RuntimeException {
  public function __construct(
    private string $name,
    private string $subTest,
    private Throwable $failure,
  )[] {
    parent::__construct('Inner test failed');
  }

  public function getQualifiedName()[]: string {
    return $this->name.' @ '.$this->subTest;
  }

  public function getFailure()[]: Throwable {
    return $this->failure;
  }
}
