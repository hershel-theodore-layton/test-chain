/** test-chain is MIT licensed, see /LICENSE. */
namespace HTL\TestChain;

use type Throwable;

final class TestFailure implements TestResult {
  public function __construct(
    private string $name,
    private Throwable $failure,
  )[] {}

  public function getFailure()[]: Throwable {
    return $this->failure;
  }

  public function getName()[]: string {
    return $this->name;
  }

  public function isSuccess()[]: bool {
    return false;
  }
}
