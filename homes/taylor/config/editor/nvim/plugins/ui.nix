_: {
  config = {
    plugins = {
      web-devicons.enable = true;

      lualine = {
        enable = true;
        settings = {
          options = {
            globalstatus = true;
            disabled_filetypes = {
              statusline = [
                "dashboard"
                "alpha"
                "starter"
              ];
            };
          };
        };
      };

      bufferline = {
        enable = true;
        settings = {
          options = {
            diagnostics = "nvim_lsp";
            always_show_bufferline = false;
            separator_style = "slant";
            offsets = [
              {
                filetype = "neo-tree";
                text = "File Explorer";
                highlight = "Directory";
                text_align = "left";
              }
            ];
          };
        };
      };

      neo-tree = {
        enable = true;
        settings = {
          filesystem = {
            filtered_items = {
              hide_dotfiles = false;
              hide_gitignored = false;
            };
            follow_current_file = {
              enabled = true;
            };
          };
          window = {
            position = "left";
            width = 30;
          };
        };
      };

      indent-blankline = {
        enable = true;
        settings = {
          indent = {
            char = "│";
          };
          scope = {
            enabled = true;
            show_start = true;
          };
        };
      };

      which-key = {
        enable = true;
      };
    };
  };
}
