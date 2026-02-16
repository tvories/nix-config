{
  pkgs,
  inputs,
  ...
}:

inputs.nixvim.legacyPackages.${pkgs.stdenv.hostPlatform.system}.makeNixvimWithModule {
  inherit pkgs;
  extraSpecialArgs = { };
  module = {
    imports = [ ../homes/taylor/config/editor/nvim ];
  };
}
