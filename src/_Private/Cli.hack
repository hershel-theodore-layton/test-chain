/** test-chain is MIT licensed, see /LICENSE. */
namespace HTL\TestChain\_Private;

final class Cli {
  public function __construct(
    private string $workingDirectory,
    private vec<string> $argv,
  )[] {}

  public static async function goAsync(
    string $working_directory,
    vec<string> $argv,
  )[defaults]: Awaitable<void> {
    $self = new static($working_directory, $argv);
    return await $self->runAsync();
  }

  private async function runAsync()[defaults]: Awaitable<void> {
    echo "Hello, world!\n";
  }
}
