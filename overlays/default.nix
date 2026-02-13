{
  inputs,
  ...
}:
{
  rust-overlay = inputs.rust-overlay.overlays.default;

  additions = final: prev: {
    # flake = import ../pkgs {
    #   pkgs = prev;
    #   inherit inputs;
    # };
  };

  modifications = final: prev: {
    # kubecm = prev.kubecm.overrideAttrs (_: prev: {
    #   meta = prev.meta // {
    #     mainProgram = "kubecm";
    #   };
    # });
    inetutils = prev.inetutils.overrideAttrs (oldAttrs: rec {
      version = "2.6";
      src = prev.fetchurl {
        url = "mirror://gnu/inetutils/inetutils-${version}.tar.xz";
        hash = "sha256-aL7b/q9z99hr4qfZm8+9QJPYKfUncIk5Ga4XTAsjV8o=";
      };
    });
  };

  # The unstable nixpkgs set (declared in the flake inputs) will
  # be accessible through 'pkgs.unstable'
  unstable-packages = final: _prev: {
    unstable = import inputs.nixpkgs-unstable {
      inherit (final) system;
      config.allowUnfree = true;
    };
  };

  # node-build-fix = final: prev: {
  #   nodejs = prev.nodejs_22;
  #   nodejs-slim = prev.nodejs-slim_22;
  # };
}
