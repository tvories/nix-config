{
  pkgs,
  lib,
  fetchFromGitHub,
  ...
}:
let
  inherit (pkgs.stdenv.hostPlatform) isDarwin;
  inherit (pkgs.darwin.apple_sdk.frameworks) Security SystemConfiguration;
  rustPlatform = pkgs.makeRustPlatform {
    cargo = pkgs.rust-bin.stable.latest.minimal;
    rustc = pkgs.rust-bin.stable.latest.minimal;
  };
in
rustPlatform.buildRustPackage rec {
  pname = "usage-cli";
  version = "2.0.3";

  src = fetchFromGitHub {
    owner = "jdx";
    repo = "usage";
    rev = "v${version}";
    hash = "sha256-zjQjFrNaFgpCCuwogbNTNMHKzDDzwRNmzUMMOREzZSk=";
  };

  cargoHash = "sha256-1x3OziIzAZHwLAEBE5yhyvI6L0k2moxLfBlcDcXzfi8=";

  buildInputs = lib.optionals isDarwin [
    Security
    SystemConfiguration
  ];

  meta = {
    homepage = "https://usage.jdx.dev";
    description = "A specification for CLIs";
    changelog = "https://github.com/jdx/usage/releases/tag/v${version}";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ bjw-s ];
    mainProgram = "usage";
  };
}
