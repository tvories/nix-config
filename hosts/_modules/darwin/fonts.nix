{ pkgs, ... }:
{
  fonts = {
    packages = with pkgs; [
      font-awesome
      monaspace
      atkinson-hyperlegible
      nerd-fonts.jetbrains-mono
      nerd-fonts.droid-sans-mono
      nerd-fonts.fira-code
    ];
  };
}
