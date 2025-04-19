{
  lib,
  config,
  pkgs,
  ...
}:
{
  modules = {
    kubernetes.enalbe = true;
  };
}
