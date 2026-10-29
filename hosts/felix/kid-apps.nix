# The kid's games and learning apps, as launchers on the XFCE desktop and in
# the applications menu. The list below is the single source: each entry is
# installed for the kid user and gets a launcher.
{
  lib,
  pkgs,
  ...
}:
let
  app = pkg: bin: icon: name: {
    inherit name pkg;
    exec = lib.getExe' pkg bin;
    icon = "${pkg}/${icon}";
  };
  # Kiosk mode keeps the site full screen (Alt+F4 closes it).
  web = name: url: {
    inherit name;
    pkg = pkgs.firefox;
    exec = "${lib.getExe pkgs.firefox} --kiosk ${url}";
    icon = "${pkgs.firefox}/share/icons/hicolor/128x128/apps/firefox.png";
  };

  apps = with pkgs; [
    # Typing
    (app klavaro "klavaro" "share/icons/hicolor/64x64/apps/klavaro.png" "Klavaro")
    (app tuxtype "tuxtype" "share/tuxtype/images/icons/icon.png" "Tux Typing")
    (app kdePackages.ktouch "ktouch" "share/icons/hicolor/128x128/apps/ktouch.png" "KTouch")
    (web "TypingClub" "https://www.typingclub.com/")
    # Learning
    (app gcompris "gcompris-qt" "share/icons/hicolor/256x256/apps/gcompris-qt.png" "GCompris")
    (app tuxpaint "tuxpaint" "share/tuxpaint/images/title-tuxpaint-2x.png" "Tux Paint")
    (web "PBS KIDS Games" "https://pbskids.org/games")
    (web "Starfall" "https://www.starfall.com/h/")
    # Games
    (app supertux "supertux2" "share/pixmaps/supertux.png" "SuperTux")
    (app supertuxkart "supertuxkart" "share/icons/hicolor/512x512/apps/supertuxkart.png" "SuperTuxKart")
    (app extremetuxracer "etr" "share/pixmaps/etr.png" "Extreme Tux Racer")
    (app neverball "neverball" "share/neverball/data/icon/neverball.png" "Neverball")
    (app pingus "pingus" "share/icons/hicolor/128x128/apps/pingus.png" "Pingus")
  ];

  launchers = pkgs.symlinkJoin {
    name = "kid-launchers";
    paths = map (
      a:
      pkgs.makeDesktopItem {
        name = "kid-" + lib.toLower (lib.replaceStrings [ " " ] [ "-" ] a.name);
        desktopName = a.name;
        inherit (a) exec icon;
        categories = [ "Game" ];
        # Marks launchers this module owns, so removed apps leave the desktop.
        extraConfig."X-Felix-Kid" = "true";
      }
    ) apps;
    # Fail the build if a package update moves an icon or binary.
    postBuild = lib.concatMapStrings (a: ''
      test -e ${lib.escapeShellArg a.icon}
      test -x ${lib.escapeShellArg (lib.head (lib.splitString " " a.exec))}
    '') apps;
  };

  # xfdesktop only runs a desktop launcher that is executable and whose
  # checksum is recorded as trusted in gvfs metadata, so the launchers are
  # copied in (not symlinked from the read-only store) and trusted at login.
  desktopIcons = pkgs.writeShellApplication {
    name = "kid-desktop-icons";
    runtimeInputs = with pkgs; [
      coreutils
      gnugrep
      glib
    ];
    text = ''
      desktop=$HOME/Desktop
      mkdir -p "$desktop"
      for old in "$desktop"/*.desktop; do
        if [ -e "$old" ] && grep -q '^X-Felix-Kid=true' "$old"; then
          rm -f "$old"
        fi
      done
      for src in ${launchers}/share/applications/*.desktop; do
        dest=$desktop/$(basename "$src")
        install -m 755 "$src" "$dest"
        gio set -t string "$dest" metadata::xfce-exe-checksum "$(sha256sum "$dest" | cut -d' ' -f1)"
      done
    '';
  };
in
{
  users.users.kid.packages = lib.unique (map (a: a.pkg) apps) ++ [
    launchers
    # Cozy Kids Launcher (on trial, installed into kid's home by its own
    # installer) runs a Python server and shows it in a Chromium kiosk.
    pkgs.python3
    pkgs.chromium
  ];

  environment.etc."xdg/autostart/kid-desktop-icons.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Kid desktop icons
    Exec=sh -c '[ "$USER" = kid ] && exec ${lib.getExe desktopIcons}'
    X-GNOME-Autostart-enabled=true
  '';
}
