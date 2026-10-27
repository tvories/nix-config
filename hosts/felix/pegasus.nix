# Pegasus Frontend as the kid's start screen: a full-screen tile launcher
# (like the library's kids' PCs) that opens on login. The collections below
# are the single list of kid apps: each one is installed for the kid user and
# shown as a tile.
#
# Pegasus only lists games backed by an existing file, so each entry gets an
# empty placeholder file next to the generated metadata.pegasus.txt.
{
  lib,
  pkgs,
  ...
}:
let
  app = pkg: bin: icon: name: {
    inherit name pkg;
    launch = lib.getExe' pkg bin;
    icon = "${pkg}/${icon}";
  };
  # Kiosk mode keeps it a full-screen "game" (Alt+F4 returns to Pegasus).
  web = name: url: {
    inherit name;
    pkg = pkgs.firefox;
    launch = "${lib.getExe pkgs.firefox} --kiosk ${url}";
    icon = "${pkgs.firefox}/share/icons/hicolor/128x128/apps/firefox.png";
  };

  # Listed in this order in Pegasus.
  collections = [
    {
      name = "Typing";
      games = with pkgs; [
        (app klavaro "klavaro" "share/icons/hicolor/64x64/apps/klavaro.png" "Klavaro")
        (app tuxtype "tuxtype" "share/tuxtype/images/icons/icon.png" "Tux Typing")
        (app kdePackages.ktouch "ktouch" "share/icons/hicolor/128x128/apps/ktouch.png" "KTouch")
        (web "TypingClub" "https://www.typingclub.com/")
      ];
    }
    {
      name = "Learning";
      games = with pkgs; [
        (app gcompris "gcompris-qt" "share/icons/hicolor/256x256/apps/gcompris-qt.png" "GCompris")
        (app tuxpaint "tuxpaint" "share/tuxpaint/images/title-tuxpaint-2x.png" "Tux Paint")
        (web "PBS KIDS Games" "https://pbskids.org/games")
        (web "Starfall" "https://www.starfall.com/h/")
      ];
    }
    {
      name = "Games";
      games = with pkgs; [
        (app supertux "supertux2" "share/pixmaps/supertux.png" "SuperTux")
        (app supertuxkart "supertuxkart" "share/icons/hicolor/512x512/apps/supertuxkart.png" "SuperTuxKart")
        (app extremetuxracer "etr" "share/pixmaps/etr.png" "Extreme Tux Racer")
        (app neverball "neverball" "share/neverball/data/icon/neverball.png" "Neverball")
        (app pingus "pingus" "share/icons/hicolor/128x128/apps/pingus.png" "Pingus")
      ];
    }
  ];

  allGames = lib.concatMap (c: c.games) collections;
  slug = name: lib.toLower (lib.replaceStrings [ " " ] [ "-" ] name) + ".game";

  metadata = lib.concatStringsSep "\n" (
    lib.imap1 (i: c: ''
      collection: ${c.name}
      sort-by: ${toString i}
      files:
      ${lib.concatMapStringsSep "\n" (g: "  ${slug g.name}") c.games}
    '') collections
    ++ map (g: ''
      game: ${g.name}
      file: ${slug g.name}
      launch: ${g.launch}
      assets.box_front: ${g.icon}
      assets.logo: ${g.icon}
    '') allGames
  );

  gamesDir = pkgs.runCommand "pegasus-kid-games" { inherit metadata; passAsFile = [ "metadata" ]; } ''
    mkdir -p $out
    cp "$metadataPath" $out/metadata.pegasus.txt
    ${lib.concatMapStrings (g: ''
      # Fail the build if a package update moves an icon or binary.
      test -e ${lib.escapeShellArg g.icon}
      test -x ${lib.escapeShellArg (lib.head (lib.splitString " " g.launch))}
      touch $out/${slug g.name}
    '') allGames}
  '';

  gameDirs = pkgs.writeText "pegasus-game-dirs.txt" "${gamesDir}\n";
in
{
  users.users.kid.packages = lib.unique (map (g: g.pkg) allGames) ++ [ pkgs.pegasus-frontend ];

  # Pegasus reads its game directories from ~/.config/pegasus-frontend; the
  # directory itself stays writable for the settings Pegasus saves there.
  systemd.tmpfiles.rules = [
    "d /home/kid/.config 0700 kid users -"
    "d /home/kid/.config/pegasus-frontend 0755 kid users -"
    "L+ /home/kid/.config/pegasus-frontend/game_dirs.txt - - - - ${gameDirs}"
  ];

  # Start full screen on the kid's login only; quitting Pegasus (its menu,
  # or Alt+F4) drops back to the XFCE desktop.
  environment.etc."xdg/autostart/pegasus-kid.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Pegasus (kid)
    Exec=sh -c '[ "$USER" = kid ] && exec ${lib.getExe pkgs.pegasus-frontend}'
    X-GNOME-Autostart-enabled=true
  '';
}
