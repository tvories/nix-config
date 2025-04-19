{
  lib,
  config,
  pkgs,
  ...
}:
{
  modules = {
    kubernetes.enalbe = true;
    shell = {
      git = {
        enable = true;
        username = "Taylor Vories";
        email = "taylor@tmtech.me";
      };
    };
  };
}
