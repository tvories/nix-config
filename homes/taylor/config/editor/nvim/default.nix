{
  ...
}:
{
  imports = [
    ./colorschemes/kanagawa.nix

    ./autocommands.nix
    ./options.nix

    ./utils/todo-comments.nix

    ./plugins/ui.nix
    ./plugins/editor.nix
    ./plugins/treesitter.nix
    ./plugins/lsp.nix
    ./plugins/completion.nix
    ./plugins/formatting.nix
  ];
}
