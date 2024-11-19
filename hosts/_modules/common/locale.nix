{
  lib,
  ...
}: {
  time.timeZone = lib.mkDefault "America/Denver";
  environment .variables = {
    LANG = "en_US.UTF-8";
    LC_ALL = "en_US.UTF-8";
  };
}