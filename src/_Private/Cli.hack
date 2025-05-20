/** test-chain is MIT licensed, see /LICENSE. */
namespace HTL\TestChain\_Private;

use namespace HH;
use namespace HH\Lib\{C, File, OS, Regex, Str, Vec};
use type Exception, RecursiveDirectoryIterator, SplFileInfo;
use function dirname, is_dir, mkdir;
use const PHP_EOL;

final class Cli {
  const type TFunction =
    shape('is_async' => bool, 'namespace' => string, 'name' => string /*_*/);
  private string $configPath;
  private bool $isDryRun;
  private bool $runTests;

  public function __construct(
    private string $workingDirectory,
    vec<string> $argv,
  )[] {
    $this->isDryRun = C\contains($argv, '--ci');
    $this->runTests = $this->isDryRun || C\contains($argv, '--run');
    $this->configPath = $this->workingDirectory.'/tests/test-chain/config.json';
  }

  public static async function goAsync(
    string $working_directory,
    vec<string> $argv,
  )[defaults]: Awaitable<void> {
    $self = new static($working_directory, $argv);
    return await $self->runAsync();
  }

  private async function runAsync()[defaults]: Awaitable<void> {
    $config = await $this->runInitialSetupAsync();
    await static::terminateOnErrorAsync(
      () ==> $this->runWriteChainAsync($config),
    );
    if ($this->runTests) {
      $entrypoint = $config->getNamespace().'\\run_tests_async';
      await HH\dynamic_fun($entrypoint)();
    }
  }

  private async function runInitialSetupAsync()[defaults]: Awaitable<Config> {
    try {
      $config_text = await $this->fileGetContentsAsync($this->configPath);
      return
        static::terminateOnError(() ==> Config::fromContents($config_text));
    } catch (OS\NotFoundException $_) {
      $config_dir = dirname($this->configPath);
      if (!is_dir($config_dir)) {
        mkdir($config_dir);
      }
    }

    $config = Config::getDefault();
    await static::terminateOnErrorAsync(async () ==> {
      concurrent {
        await $this->filePutContentsAsync($this->configPath, $config->toJson());
        await $this->runWriteChainAsync($config);
        await $this->runWriteRunDotHackAsync($config);
      }
    });

    echo Str\format(
      "Wrote initial setup. You can edit these to your liking:\n\t%s\n\t%s\n".
      "Open Source software projects should edit config.json:license_comment.\n",
      $this->configPath,
      $config->getRunDotHackPath($this->workingDirectory),
    );
    exit(1);
  }

  private async function runWriteChainAsync(
    Config $config,
  )[defaults]: Awaitable<void> {
    $test_files = new RecursiveDirectoryIterator(
      $config->getTestDir($this->workingDirectory),
      RecursiveDirectoryIterator::SKIP_DOTS,
    )
      |> Vec\filter(
        $$,
        $file_info ==> $file_info as SplFileInfo->getExtension() === 'hack',
      );

    $tests = await Vec\map_async(
      $test_files,
      async $file_info ==>
        await $this->fileGetContentsAsync($file_info->getPathname())
        |> Str\split($$, "\n")
        |> static::parseTestsFromFile($file_info->getPathname(), $$)
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

async function tests_async<T as TestChain\Chain>(
  TestChain\ChainController<T> $controller
)[defaults]: Awaitable<TestChain\ChainController<T>> {
  return $controller
__TESTS__;
}

HACK;

    await $this->filePutContentsAsync(
      $config->getChainDotHackPath($this->workingDirectory),
      Str\replace_every($contents, dict[
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

use namespace HH;
use namespace HH\Lib\{IO, Vec};
use namespace HTL\TestChain;

<<__DynamicallyCallable, __EntryPoint>>
async function run_tests_async()[defaults]: Awaitable<void> {
  $_argv = HH\global_get('argv') as Container<_>
    |> Vec\map($$, $x ==> $x as string);
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

  private static function terminateOnError<T>(
    (function()[defaults]: T) $func,
  )[defaults]: T {
    try {
      return $func();
    } catch (Exception $e) {
      echo $e->getMessage().PHP_EOL;
      exit(1);
    }
  }

  private static async function terminateOnErrorAsync<T>(
    (function()[defaults]: Awaitable<T>) $func,
  )[defaults]: Awaitable<T> {
    try {
      return await $func();
    } catch (Exception $e) {
      echo $e->getMessage().PHP_EOL;
      exit(1);
    }
  }
}
