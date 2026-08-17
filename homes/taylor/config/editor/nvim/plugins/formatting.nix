_:
{
  config = {
    plugins.conform-nvim = {
      enable = true;
      settings = {
        format_on_save = {
          lsp_fallback = true;
          timeout_ms = 500;
        };
        formatters_by_ft = {
          nix = [ "nixfmt" ];
          go = [ "gofmt" ];
          terraform = [ "terraform_fmt" ];
          json = [ "prettier" ];
          yaml = [ "prettier" ];
          markdown = [ "prettier" ];
          lua = [ "stylua" ];
          sh = [ "shfmt" ];
          "_" = [ "trim_whitespace" ];
        };
      };
    };
  };
}
