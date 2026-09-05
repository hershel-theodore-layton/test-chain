/** test-chain is MIT licensed, see /LICENSE. */
namespace HTL\TestChain;

use type Throwable;

interface TestResult {
  /**
   * @throws If you invoke this when `->isSuccess()` is true.
   */
  public function getFailure()[]: Throwable;
  public function getName()[]: string;
  public function isSuccess()[]: bool;
}
