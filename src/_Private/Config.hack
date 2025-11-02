/** test-chain is MIT licensed, see /LICENSE. */
namespace HTL\TestChain\_Private;

use namespace HH\Lib\{Dict, SecureRandom};
use type RuntimeException;
use function json_decode_with_error, json_encode_with_error;
use const JSON_FB_HACK_ARRAYS,
  JSON_PRETTY_PRINT,
  JSON_UNESCAPED_SLASHES,
  JSON_UNESCAPED_UNICODE;

final class Config {
  const string DEFAULT_CHAIN_PATH = 'tests/test-chain/chain.hack';
  const string DEFAULT_CHAIN_TYPE = '\\HTL\\TestChain\\Chain';
  const string DEFAULT_LICENSE_COMMENT =
    '/** This project is unlicensed. No license has been granted. */';
  const string DEFAULT_RUN_FILE = 'tests/test-chain/run.hack';

  const type TJson = shape(
    ?'chain_path' => string,
    ?'chain_type' => string,
    'codegen_namespace' => string,
    ?'license_comment' => string,
    ?'run_file' => string,
    ...
  );

  public function __construct(private this::TJson $json)[] {}

  public function getChainDotHackPath(string $working_directory)[]: string {
    return $working_directory.
      '/'.
      ($this->json['chain_path'] ?? static::DEFAULT_CHAIN_PATH);
  }

  public function getChainType()[]: string {
    return $this->json['chain_type'] ?? '\\HTL\\TestChain\\Chain';
  }

  public function getLicenseComment()[]: string {
    return $this->json['license_comment'] ?? static::DEFAULT_LICENSE_COMMENT;
  }

  public function getNamespace()[]: string {
    return $this->json['codegen_namespace'];
  }

  public function getRunDotHackPath(string $working_directory)[]: string {
    return $working_directory.
      '/'.
      ($this->json['run_file'] ?? static::DEFAULT_RUN_FILE);
  }

  public function toJson()[defaults]: string {
    $_error = null;
    return json_encode_with_error(
      $this->json,
      inout $_error,
      JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE,
    ) as string;
  }

  public function resetToDefaultsKeepCommonOverrides()[write_props]: void {
    $this->json['chain_path'] = static::DEFAULT_CHAIN_PATH;
    $this->json['chain_type'] = static::DEFAULT_CHAIN_TYPE;
    $this->json['run_file'] = static::DEFAULT_RUN_FILE;
    $this->json =
      Shapes::toDict($this->json) |> Dict\sort_by_key($$) as self::TJson;
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
    $self = new static(shape(
      'chain_path' => '__ERROR_INCOMPLETE_RESET_TO_DEFAULTS_FILE_A_GH_ISSUE__',
      'chain_type' => '__ERROR_INCOMPLETE_RESET_TO_DEFAULTS_FILE_A_GH_ISSUE__',
      'codegen_namespace' => static::pickNamespace(),
      'license_comment' => static::DEFAULT_LICENSE_COMMENT,
      'run_file' => '__ERROR_INCOMPLETE_RESET_TO_DEFAULTS_FILE_A_GH_ISSUE__',
    ));
    $self->resetToDefaultsKeepCommonOverrides();
    return $self;
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
