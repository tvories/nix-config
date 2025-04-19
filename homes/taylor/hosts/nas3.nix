{
  lib,
  config,
  pkgs,
  ...
}:
{
  modules = {
    kubernetes.enalbe = true;
    git = {
      enable = true;
      username = "Taylor Vories";
      email = "taylor@tmtech.me";
  };
}
