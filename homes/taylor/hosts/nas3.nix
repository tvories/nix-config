{
  lib,
  config,
  pkgs,
  ...
}:
{
  modules = {
    kubernetes.enable = true;
    development.enable = true;
    shell = {
      git = {
        enable = true;
        username = "Taylor Vories";
        email = "taylor@tmtech.me";
      };
    };
  };
}
