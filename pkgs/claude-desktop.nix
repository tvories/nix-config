# Anthropic's Claude desktop app (Linux beta). Anthropic ships it only as a
# .deb for Ubuntu/Debian, so this unpacks that and patches its binaries for
# NixOS. It doesn't update itself: bump version and hash from the apt index,
#   https://downloads.claude.ai/claude-desktop/apt/stable/dists/stable/main/binary-amd64/Packages
{
  lib,
  stdenv,
  fetchurl,
  dpkg,
  autoPatchelfHook,
  makeWrapper,
  wrapGAppsHook3,
  alsa-lib,
  at-spi2-atk,
  cups,
  dbus,
  expat,
  gtk3,
  libdrm,
  libgbm,
  libnotify,
  libsecret,
  libuuid,
  libxkbcommon,
  libGL,
  libcap_ng,
  libseccomp,
  nspr,
  nss,
  pango,
  pipewire,
  systemd,
  libx11,
  libxcb,
  libxcomposite,
  libxdamage,
  libxext,
  libxfixes,
  libxrandr,
  libxshmfence,
  libxtst,
  xdg-utils,
}:
stdenv.mkDerivation rec {
  pname = "claude-desktop";
  version = "4.16336.0";

  src = fetchurl {
    url = "https://downloads.claude.ai/claude-desktop/apt/stable/pool/main/c/claude-desktop/claude-desktop_${version}_amd64.deb";
    hash = "sha256:3810733e93792f70eae921175d13e53d1cc6bdce9dc23117f0588087521a64bc";
  };

  nativeBuildInputs = [
    dpkg
    autoPatchelfHook
    makeWrapper
    wrapGAppsHook3
  ];

  buildInputs = [
    alsa-lib
    at-spi2-atk
    cups
    dbus
    expat
    gtk3
    libdrm
    libgbm
    libnotify
    libsecret
    libuuid
    libxkbcommon
    # For the bundled virtiofsd, which Cowork's VM uses.
    libcap_ng
    libseccomp
    nspr
    nss
    pango
    pipewire
    systemd
    stdenv.cc.cc.lib
    libx11
    libxcb
    libxcomposite
    libxdamage
    libxext
    libxfixes
    libxrandr
    libxshmfence
    libxtst
  ];

  # Let wrapGAppsHook3's settings go into the makeWrapper call below instead of
  # a second wrapper.
  dontWrapGApps = true;

  unpackPhase = ''
    runHook preUnpack
    # Not `dpkg-deb -x`: it tries to keep chrome-sandbox setuid, which the
    # build sandbox refuses. Electron uses user namespaces instead.
    dpkg-deb --fsys-tarfile $src | tar -x --no-same-owner --no-same-permissions
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/lib
    cp -r usr/lib/claude-desktop $out/lib/
    cp -r usr/share $out/
    rm -rf $out/share/lintian

    # libGL and libvulkan are loaded at runtime with dlopen, which autoPatchelf
    # can't see. The Ozone flags give a native Wayland window when the session
    # asks for one (NIXOS_OZONE_WL, set by Plasma on NixOS).
    # makeShellWrapper, not makeWrapper: wrapGAppsHook3 swaps makeWrapper for
    # the binary wrapper, which can't expand the ''${…} in --add-flags and
    # passed it as literal arguments. Those landed ahead of the claude:// URL
    # on deep links, so the app never saw its login callback.
    makeShellWrapper $out/lib/claude-desktop/claude-desktop $out/bin/claude-desktop \
      "''${gappsWrapperArgs[@]}" \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ libGL ]} \
      --prefix PATH : ${lib.makeBinPath [ xdg-utils ]} \
      --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations}}"

    runHook postInstall
  '';

  meta = {
    description = "Claude desktop app: chat, Cowork and Claude Code (Linux beta)";
    homepage = "https://claude.ai/download";
    license = lib.licenses.unfree;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "claude-desktop";
  };
}
