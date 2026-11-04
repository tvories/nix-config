# Games: Steam with Proton for most of the library, Heroic for Epic and GOG,
# Lutris for Battle.net (WoW, Overwatch, Diablo) and the EA app.
{ pkgs, ... }:
{
  programs.steam = {
    enable = true;
    # Proton-GE carries fixes and codecs that Valve's Proton waits on; pick it
    # per game under Properties > Compatibility.
    extraCompatPackages = [ pkgs.proton-ge-bin ];
    remotePlay.openFirewall = true;
  };
  # Raises CPU and GPU priority while a game runs (`gamemoderun %command%`).
  programs.gamemode.enable = true;

  environment.systemPackages = with pkgs; [
    heroic
    lutris
    mangohud
    # Downloads Wine/Proton and DXVK builds for Lutris and Steam (e.g. the
    # specific versions Lutris's Blizzard installers recommend).
    protonplus
  ];
}
