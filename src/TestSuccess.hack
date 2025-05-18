/** test-chain is MIT licensed, see /LICENSE. */
namespace HTL\TestChain;

use type InvalidOperationException;

final class TestSuccess implements TestResult {
  public function __construct(private string $name)[] {}

  public function getFailure()[]: nothing {
    throw new InvalidOperationException(
      'This test passed, you may not ask for a failure.',
    );
  }

  public function getName()[]: string {
    return $this->name;
  }

  public function isSuccess()[]: bool {
    return true;
  }
}
