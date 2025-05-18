/** test-chain is MIT licensed, see /LICENSE. */
namespace HTL\TestChain\_Private;

use namespace HH\Lib\SecureRandom;
use type RuntimeException;
use function json_decode_with_error, json_encode_with_error;
use const JSON_FB_HACK_ARRAYS,
  JSON_PRETTY_PRINT,
  JSON_UNESCAPED_SLASHES,
  JSON_UNESCAPED_UNICODE;

final class Config {
  const type TJson = shape(
    'chain_path' => string,
    'codegen_namespace' => string,
    'license_comment' => string,
    'run_file' => string,
    'test_dir' => string,
    ...
  );

  public function __construct(private this::TJson $json)[] {}

  public function getChainDotHackPath(string $working_directory)[]: string {
    return $working_directory.
      '/'.
      $this->json['test_dir'].
      '/'.
      $this->json['chain_path'];
  }

  public function getLicenseComment()[]: string {
    return $this->json['license_comment'];
  }

  public function getNamespace()[]: string {
    return $this->json['codegen_namespace'];
  }

  public function getRunDotHackPath(string $working_directory)[]: string {
    return $working_directory.
      '/'.
      $this->json['test_dir'].
      '/'.
      $this->json['run_file'];
  }

  public function getTestDir(string $working_directory)[]: string {
    return $working_directory.'/'.$this->json['test_dir'];
  }

  public function toJson()[defaults]: string {
    $_error = null;
    return json_encode_with_error(
      $this->json,
      inout $_error,
      JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE,
    );
  }

  public static function fromContents(string $contents)[]: this {
    // immediately invoked lambda to cast the unknown type to `mixed`.
    $structure = (
      (): mixed ==> {
        $error = null;
        $json = json_decode_with_error(
          $contents,
          inout $error,
          true,
          512,
          JSON_FB_HACK_ARRAYS,
        );

        if ($error is nonnull) {
          throw new RuntimeException($error[1].' Invalid config: '.$contents);
        }

        return $json;
      }
    )();

    if (!$structure is this::TJson) {
      throw new RuntimeException(
        'Invalid config: Does not match the Config::TJson structure',
      );
    }

    return new static($structure);
  }

  public static function getDefault()[defaults]: this {
    return new static(shape(
      'chain_path' => 'test-chain/chain.hack',
      'codegen_namespace' => static::pickNamespace(),
      'license_comment' =>
        '/** This project is unlicensed. No license has been granted. */',
      'run_file' => 'run.hack',
      'test_dir' => 'tests',
    ));
  }

  private static function pickNamespace()[defaults]: string {
    $alphabet =
      'abcdefghijklmnopqrstuvwxyz'.'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.'0123456789';
    // This is more than 70 bits of randomness.
    // It would take a human lifetime to have a 10% chance
    // to create a duplicate namespace if you generate 10 new
    // test namespaces every second without breaks.
    return
      'HTL\\Project_'.SecureRandom\string(12, $alphabet).'\\GeneratedTestChain';
  }
}
