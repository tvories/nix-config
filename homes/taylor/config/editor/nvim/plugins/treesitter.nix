_:
{
  config = {
    plugins = {
      treesitter = {
        enable = true;
        nixGrammars = true;
        settings = {
          highlight = {
            enable = true;
            additional_vim_regex_highlighting = false;
          };
          indent = {
            enable = true;
          };
          incremental_selection = {
            enable = true;
            keymaps = {
              init_selection = "<C-space>";
              node_incremental = "<C-space>";
              scope_incremental = false;
              node_decremental = "<bs>";
            };
          };
        };
      };

      treesitter-context = {
        enable = true;
        settings = {
          max_lines = 3;
        };
      };

      rainbow-delimiters = {
        enable = true;
      };
    };
  };
}
