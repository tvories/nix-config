{ pkgs, ... }:
{
  fonts = {
    packages = with pkgs; [
      fira-code-nerdfont
      font-awesome
      monaspace
      atkinson-hyperlegible
      # nerdfonts
      (nerdfonts.override {
        fonts = [
          "JetBrainsMono"
          "DroidSansMono"
        ];
      })
    ];
  };
}
