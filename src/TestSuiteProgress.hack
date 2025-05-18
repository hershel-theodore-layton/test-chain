/** test-chain is MIT licensed, see /LICENSE. */
namespace HTL\TestChain;

/**
 * Please instantiate with `test_suite_progress_create`.
 * New fields required fields will be added in the future.
 * Code that created this shape manually would break.
 * This is not considered a breaking change, because of this note.
 */
type TestSuiteProgress = shape(
  'total_number_of_tests' => int,
  'number_of_tests_ran' => int,
  ...
);

function test_suite_progress_create()[]: TestSuiteProgress {
  return shape(
    'total_number_of_tests' => 0,
    'number_of_tests_ran' => 0,
  );
}
