/** test-chain is MIT licensed, see /LICENSE. */
namespace HTL\TestChain;

use type Throwable;

interface TestResult {
  /**
   * @throws If you invoke this on `->isSuccess()` true.
   */
  public function getFailure()[]: Throwable;
  public function getName()[]: string;
  public function isSuccess()[]: bool;
}
