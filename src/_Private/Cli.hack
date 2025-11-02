/** test-chain is MIT licensed, see /LICENSE. */
namespace HTL\TestChain\_Private;

use namespace HH;
use namespace HH\Lib\{C, File, OS, Regex, Str, Vec};
use type Exception, RecursiveDirectoryIterator, RecursiveIteratorIterator;
use function dirname, is_dir, mkdir, unlink;

final class Cli {
  const type TFunction =
    shape('is_async' => bool, 'namespace' => string, 'name' => string /*_*/);
  private string $configPath;
  private bool $isDryRun;
  private bool $printHelp;
  private bool $printHelpExtended;
  private bool $reset;
  private bool $runTests;
  private bool $update;

  public function __construct(
    private string $workingDirectory,
    vec<string> $argv,
  )[] {
    $this->isDryRun = C\contains($argv, '--ci');
    $this->printHelp = C\contains($argv, '--help');
    $this->printHelpExtended =
      C\contains($argv, '--help-ext') || C\contains($argv, '--man');
    $this->reset = C\contains($argv, '--reset');
    $this->runTests = $this->isDryRun || C\contains($argv, '--run');
    $this->update = $this->reset || C\contains($argv, '--update');
    $this->configPath = $this->workingDirectory.'/tests/test-chain/config.json';
  }

  public static async function goAsync(
    string $working_directory,
    vec<string> $argv,
  )[defaults]: Awaitable<void> {
    $self = new static($working_directory, $argv);
    try {
      return await $self->runAsync();
    } catch (Exception $e) {
      echo $e->getMessage();
      exit(1);
    }
  }

  private async function runAsync()[defaults]: Awaitable<void> {
    if ($this->printHelpExtended) {
      echo HELP_EXTENDED;
    }

    if ($this->printHelp) {
      echo HELP;
      return;
    }

    $config = await $this->readConfigAsync();

    if ($this->update) {
      unlink($config->getChainDotHackPath($this->workingDirectory));
      unlink($config->getRunDotHackPath($this->workingDirectory));
    }

    if ($this->reset) {
      $config->resetToDefaultsKeepCommonOverrides();
    }

    concurrent {
      await $this->runWriteChainAsync($config);
      await $this->runWriteRunDotHackAsync($config);
    }

    if ($this->runTests) {
      $entrypoint = $config->getNamespace().'\\run_tests_async';
      await HH\dynamic_fun($entrypoint)();
    }

    await $this->filePutContentsAsync($this->configPath, $config->toJson());
  }

  private async function readConfigAsync()[defaults]: Awaitable<Config> {
    try {
      $config_text = await $this->fileGetContentsAsync($this->configPath);
      return Config::fromContents($config_text);
    } catch (OS\NotFoundException $_) {
      $config_dir = dirname($this->configPath) as string;
      if (!is_dir($config_dir)) {
        mkdir($config_dir);
      }
      return Config::getDefault();
    }
  }

  private async function runWriteChainAsync(
    Config $config,
  )[defaults]: Awaitable<void> {
    $test_files = new RecursiveDirectoryIterator(
      $this->workingDirectory.'/tests',
      RecursiveDirectoryIterator::SKIP_DOTS,
    )
      |> new RecursiveIteratorIterator($$)
      |> Vec\filter($$, $file_info ==> $file_info->getExtension() === 'hack');

    $tests = await Vec\map_async(
      $test_files,
      async $file_info ==>
        await $this->fileGetContentsAsync($file_info->getPathname() as string)
        |> Str\split($$, "\n")
        |> static::parseTestsFromFile($file_info->getPathname() as string, $$)
        |> vec($$),
    )
      |> Vec\flatten($$)
      |> Vec\sort_by($$, $x ==> Str\lowercase($x['namespace'].'__'.$x['name']))
      |> Vec\map(
        $$,
        $test ==> $test['is_async']
          ? Str\format(
              '    ->addTestGroupAsync(%s\\%s<>)',
              $test['namespace'],
              $test['name'],
            )
          : Str\format(
              '    ->addTestGroup(%s\\%s<>)',
              $test['namespace'],
              $test['name'],
            ),
      )
      |> Str\join($$, "\n");

    $contents = <<<'HACK'
__LICENSE_COMMENT__
namespace __NAMESPACE__;

use namespace HTL\TestChain;

async function tests_async(
  TestChain\ChainController<__CHAIN_TYPE__> $controller
)[defaults]: Awaitable<TestChain\ChainController<__CHAIN_TYPE__>> {
  return $controller
__TESTS__;
}

HACK;

    await $this->filePutContentsAsync(
      $config->getChainDotHackPath($this->workingDirectory),
      Str\replace_every($contents, dict[
        '__CHAIN_TYPE__' => $config->getChainType(),
        '__LICENSE_COMMENT__' => $config->getLicenseComment(),
        '__NAMESPACE__' => $config->getNamespace(),
        '__TESTS__' => $tests,
      ]),
    );
  }

  private async function runWriteRunDotHackAsync(
    Config $config,
  )[defaults]: Awaitable<void> {
    $contents = <<<'HACK'
__LICENSE_COMMENT__
namespace __NAMESPACE__;

use namespace HH\Lib\IO;
use namespace HTL\TestChain;

// The initial stub was generated with vendor/bin/test-chain.
// It is now yours to edit and customize.
<<__DynamicallyCallable, __EntryPoint>>
async function run_tests_async()[defaults]: Awaitable<void> {
  $tests = await tests_async(
    TestChain\ChainController::create(TestChain\TestChain::create<>)
  );
  $result = await $tests
    ->withParallelGroupExecution()
    ->runAllAsync($tests->getBasicProgressReporter());

  $output = IO\request_output();
  if ($result->isSuccess()) {
    await $output->writeAllAsync("\nNo errors!\n");
    return;
  }

  await $output->writeAllAsync("\nTests failed!\n");
  exit(1);
}

HACK;

    await $this->filePutContentsAsync(
      $config->getRunDotHackPath($this->workingDirectory),
      Str\replace_every(
        $contents,
        dict[
          '__NAMESPACE__' => $config->getNamespace(),
          '__LICENSE_COMMENT__' => $config->getLicenseComment(),
        ],
      ),
    );
  }

  private static function parseTestsFromFile(
    string $file_name,
    vec<string> $lines,
  )[]: Traversable<this::TFunction> {
    $namespace = C\find($lines, $l ==> Str\starts_with($l, 'namespace ')) ?? ''
      |> Str\strip_prefix($$, 'namespace ')
      |> Str\strip_suffix($$, ';')
      |> $$ !== '' ? '\\'.$$ : '';

    $snip_function_name = $l ==> Str\split($l, 'function ', 2)[1]
      |> Regex\first_match($$, re'/[a-z_][\w]+/i') as nonnull[0];

    $is_test_line = false;
    foreach ($lines as $i => $l) {
      if ($is_test_line && Str\starts_with($l, 'function ')) {
        yield shape(
          'is_async' => false,
          'namespace' => $namespace,
          'name' => $snip_function_name($l),
        );
      } else if ($is_test_line && Str\starts_with($l, 'async function ')) {
        yield shape(
          'is_async' => true,
          'namespace' => $namespace,
          'name' => $snip_function_name($l),
        );
      } else if ($is_test_line) {
        throw new \InvalidOperationException(Str\format(
          "Expected to find a test function on line %d of %s.\n",
          $i + 1,
          $file_name,
        ));
      }

      $is_test_line = $l === '<<TestChain\\Discover>>';
    }
  }

  private async function fileGetContentsAsync(
    string $path,
  )[defaults]: Awaitable<string> {
    $file = File\open_read_only($path);
    using $file->closeWhenDisposed();
    using $file->tryLockx(File\LockType::SHARED);
    return await $file->readAllAsync();
  }

  private async function filePutContentsAsync(
    string $path,
    string $contents,
  )[defaults]: Awaitable<void> {
    if ($this->isDryRun) {
      $old_contents = await $this->fileGetContentsAsync($path);

      if ($old_contents === $contents) {
        return;
      }

      echo Str\format(
        "Codegen out of date.\nFiles should not need to change in CI.\n%s\n".
        "Before:---\n%s\n---".
        "After:---\n%s\n---",
        $path,
        $old_contents,
        $contents,
      );
      exit(1);
    }

    $file = File\open_write_only($path, File\WriteMode::TRUNCATE);
    using $file->closeWhenDisposed();
    using $file->tryLockx(File\LockType::EXCLUSIVE);
    await $file->writeAllAsync($contents);
  }
}

const string HELP = <<<'HELP'
Usage: vendor/bin/test-chain <flags>
Command reference:
 no flags   | Initialize if unintialized, do nothing else.
 --run      | Discover new tests, then invoke tests.
 --ci       | Assert codegen is up to date, then invoke tests.
 --help     | Print this help menu.
 --man      | Print the manual.
 --help-ext | An alias for `--man`.
 --update   | Create a new run.hack, loses your customizations.
 --reset    | Start fresh, will retain namespace and license header.
HELP;

const string HELP_EXTENDED = <<<'HELP'
This is the test-chain CLI. This tool discovers tests marked with the
<<TestChain\Discover>> attribute in your codebase. If you have never run
this CLI before, it will create a new directory `tests/test-chain`. It will
contain three files: `config.json`, `chain.hack`, `run.hack`. The `config.json`
file may not be renamed or moved. The `chain.hack` is not meant to be edited
and is generated anew every run. `run.hack` is yours to own and edit. You
can customize the output and use your own implementation of the `TestChain`
type. The discovery tool searches for test functions line by line, and assumes
default hackfmt formatting. If your tests don't look like:

<<TestChain\Discover>>
function name()...
or
<<TestChain\Discover>>
async function name()...

they will not be discovered.
HELP;
