/** test-chain is MIT licensed, see /LICENSE. */
namespace HTL\TestChain;

use namespace HH\Lib\{C, Vec};

final class TestGroupResult {
  public function __construct(
    private string $name,
    private vec<TestResult> $results,
  )[] {}

  public function getFailures()[]: vec<TestResult> {
    return Vec\filter($this->results, $r ==> !$r->isSuccess());
  }

  public function getName()[]: string {
    return $this->name;
  }

  public function isSuccess()[]: bool {
    return C\every($this->results, $r ==> $r->isSuccess());
  }
}
