#!/usr/bin/env hhvm
/** test-chain is MIT licensed, see /LICENSE. */
namespace HTL\TestChain\_Private;

use namespace HH;
use namespace HH\Lib\{C, Vec};
use type InvalidArgumentException;
use function dirname, file_exists, getcwd;
use const PHP_EOL;

<<__EntryPoint>>
async function bin_async()[defaults]: Awaitable<void> {
  initialize_autoloader();
  $argv = \HH\global_get('argv') as vec<_> |> Vec\map($$, $x ==> $x as string);

  $cwd = getcwd();
  $hhconfig = $cwd.'/.hhconfig';

  if (
    !file_exists($hhconfig) && !C\contains($argv, '--skip-working-dir-check')
  ) {
    echo 'This script is intended to be run at the root of your repository,'.
      ' but the hhconfig file '.
      $hhconfig.
      ' does not exist. Please run this script from the root of your repository'.
      ' or pass the --skip-working-dir-check flag to bypass this message.'.
      PHP_EOL;
    exit(1);
  }

  await Cli::goAsync($cwd, $argv);
}

/**
 * @license MIT-0
 * @copyright Hershel Theodore Layton, 2025
 *
 * This function is licensed under MIT-0. It may be copied freely without
 * restriction. Not even this docblock need to be preserved.
 */
function initialize_autoloader()[defaults]: void {
  if (HH\autoload_is_native()) {
    return;
  }

  $invoke_autoloader = () ==> {
    try {
      HH\dynamic_fun('Facebook\\AutoloadMap\\initialize')();
    } catch (InvalidArgumentException $e) {
      echo $e->getMessage();
      exit(1);
    }
  };

  $file = '/vendor/autoload.hack';

  $dir = __DIR__;
  $last_dir = $dir;

  do {
    if (HH\could_include($dir.$file)) {
      require_once $dir.$file;
      $invoke_autoloader();
      return;
    }

    $last_dir = $dir;
    $dir = dirname($dir);
  } while ($last_dir !== $dir);

  echo
    'Could not find vendor/autoload.hack and native autoloading was not enabled. '.
    'You can resolve this by enabling `hhvm.autoload.enabled = true` in your '.
    'INI settings and setting a `hhvm.autoload.db.path`. If you cannot use '.
    'native autoloading, invoke vendor/bin/hh-autoload and try again.'.
    PHP_EOL;
  exit(1);
}
