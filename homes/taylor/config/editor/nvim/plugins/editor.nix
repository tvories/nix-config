_:
{
  config = {
    plugins = {
      telescope = {
        enable = true;
        keymaps = {
          "<leader>ff" = "find_files";
          "<leader>fg" = "live_grep";
          "<leader>fb" = "buffers";
          "<leader>fh" = "help_tags";
          "<leader>fr" = "oldfiles";
          "<leader>fc" = "grep_string";
          "<leader>fd" = "diagnostics";
        };
        settings = {
          defaults = {
            file_ignore_patterns = [
              "node_modules"
              ".git/"
              "result"
            ];
          };
        };
      };

      gitsigns = {
        enable = true;
        settings = {
          signs = {
            add = {
              text = "▎";
            };
            change = {
              text = "▎";
            };
            delete = {
              text = "";
            };
            topdelete = {
              text = "";
            };
            changedelete = {
              text = "▎";
            };
            untracked = {
              text = "▎";
            };
          };
          current_line_blame = false;
          on_attach = {
            __raw = ''
              function(bufnr)
                local gs = package.loaded.gitsigns
                local function map(mode, l, r, opts)
                  opts = opts or {}
                  opts.buffer = bufnr
                  vim.keymap.set(mode, l, r, opts)
                end
                map('n', ']h', gs.next_hunk, { desc = 'Next hunk' })
                map('n', '[h', gs.prev_hunk, { desc = 'Prev hunk' })
                map('n', '<leader>gb', gs.toggle_current_line_blame, { desc = 'Toggle blame' })
                map('n', '<leader>gp', gs.preview_hunk, { desc = 'Preview hunk' })
              end
            '';
          };
        };
      };

      flash = {
        enable = true;
      };

      nvim-autopairs = {
        enable = true;
        settings = {
          check_ts = true;
        };
      };

      comment = {
        enable = true;
      };

      illuminate = {
        enable = true;
        settings = {
          delay = 200;
          large_file_cutoff = 2000;
        };
      };
    };
  };
}
