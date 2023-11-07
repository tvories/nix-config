let
  fetchTarball = builtins.fetchTarball;
  nixtar = fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/nixos-23.05.tar.gz";
  };
  nixtarUnstable = fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz";
  };
  nixpkgs = import nixtar {};
  nixpkgsUnstable = import nixtarUnstable {};
in
nixpkgs.mkShell {
  packages = [
    nixpkgs.nil
    # nixpkgs.git
    nixpkgsUnstable.btop
    nixpkgs.sops
    nixpkgs.age
  ];
}