{
  inputs,
  ...
}:
{
  rust-overlay = inputs.rust-overlay.overlays.default;

  # Replaces pkgs.claude-code everywhere with the always-current build.
  claude-code = inputs.claude-code.overlays.default;

  additions = final: prev: {
    # flake = import ../pkgs {
    #   pkgs = prev;
    #   inherit inputs;
    # };
  };

  modifications = final: prev: let inherit (prev) lib; in {
    # kubecm = prev.kubecm.overrideAttrs (_: prev: {
    #   meta = prev.meta // {
    #     mainProgram = "kubecm";
    #   };
    # });
    vscode = prev.vscode.overrideAttrs (old: {
      installPhase = "whoami\n" + old.installPhase;
    });
    # Do the same for windsurf if it's still failing
    windsurf = prev.windsurf.overrideAttrs (old: {
      installPhase = "whoami\n" + old.installPhase;
    });

    # FreeRDP 3.32 turned Ext (HYBRID_EX) security on by default, but KRdp
    # before 6.7.90 only turns NLA off. NLA clients (Windows App, mstsc) then
    # land on Ext and fail with "Could not find user in SAM database".
    # https://github.com/FreeRDP/FreeRDP/issues/13567
    kdePackages = prev.kdePackages.overrideScope (
      _: kprev: {
        krdp =
          if lib.versionOlder kprev.krdp.version "6.7.90" then
            kprev.krdp.overrideAttrs (old: {
              postPatch = (old.postPatch or "") + ''
                substituteInPlace src/RdpConnection.cpp --replace-fail \
                  'freerdp_settings_set_bool(settings, FreeRDP_NlaSecurity, false);' \
                  'freerdp_settings_set_bool(settings, FreeRDP_NlaSecurity, false);
                    freerdp_settings_set_bool(settings, FreeRDP_ExtSecurity, false);'
              '';
            })
          else
            kprev.krdp;
      }
    );
  };

  # The unstable nixpkgs set (declared in the flake inputs) will
  # be accessible through 'pkgs.unstable'
  unstable-packages = final: _prev: {
    # nixpkgs-unstable dropped x86_64-darwin support entirely (hard eval
    # assertion, not a missing-package issue) — fall back to the stable
    # set on that system rather than failing flake evaluation.
    unstable =
      if final.system == "x86_64-darwin" then
        final
      else
        import inputs.nixpkgs-unstable {
          inherit (final) system;
          config.allowUnfree = true;
        };
  };

  # node-build-fix = final: prev: {
  #   nodejs = prev.nodejs_22;
  #   nodejs-slim = prev.nodejs-slim_22;
  # };
}
