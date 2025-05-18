/** test-chain is MIT licensed, see /LICENSE. */
namespace HTL\TestChain;

use namespace HH\Lib\{C, Vec};

final class TestSuiteResult {
  public function __construct(private vec<TestGroupResult> $results)[] {}

  public function getFailures()[]: vec<TestGroupResult> {
    return Vec\filter($this->results, $r ==> !$r->isSuccess());
  }

  public function isSuccess()[]: bool {
    return C\every($this->results, $r ==> $r->isSuccess());
  }
}
