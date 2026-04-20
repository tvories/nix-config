# darwin specific packages for every system.
{ pkgs, ... }:
{
  config = {
    environment.systemPackages = with pkgs; [
      comma
    ];
  };
}
