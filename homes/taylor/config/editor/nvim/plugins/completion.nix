_:
{
  config = {
    plugins = {
      luasnip = {
        enable = true;
        settings = {
          enable_autosnippets = true;
          history = true;
          updateevents = "TextChanged,TextChangedI";
        };
      };

      friendly-snippets = {
        enable = true;
      };

      cmp-nvim-lsp.enable = true;
      cmp-buffer.enable = true;
      cmp-path.enable = true;
      cmp_luasnip.enable = true;

      cmp = {
        enable = true;
        settings = {
          snippet = {
            expand = {
              __raw = "function(args) require('luasnip').lsp_expand(args.body) end";
            };
          };
          mapping = {
            "<C-b>" = {
              __raw = "cmp.mapping.scroll_docs(-4)";
            };
            "<C-f>" = {
              __raw = "cmp.mapping.scroll_docs(4)";
            };
            "<C-Space>" = {
              __raw = "cmp.mapping.complete()";
            };
            "<C-e>" = {
              __raw = "cmp.mapping.abort()";
            };
            "<CR>" = {
              __raw = "cmp.mapping.confirm({ select = true })";
            };
            "<Tab>" = {
              __raw = ''
                cmp.mapping(function(fallback)
                  if cmp.visible() then
                    cmp.select_next_item()
                  elseif require("luasnip").expand_or_jumpable() then
                    require("luasnip").expand_or_jump()
                  else
                    fallback()
                  end
                end, { "i", "s" })
              '';
            };
            "<S-Tab>" = {
              __raw = ''
                cmp.mapping(function(fallback)
                  if cmp.visible() then
                    cmp.select_prev_item()
                  elseif require("luasnip").jumpable(-1) then
                    require("luasnip").jump(-1)
                  else
                    fallback()
                  end
                end, { "i", "s" })
              '';
            };
            "<C-n>" = {
              __raw = "cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert })";
            };
            "<C-p>" = {
              __raw = "cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert })";
            };
          };
          sources = [
            {
              name = "nvim_lsp";
            }
            {
              name = "luasnip";
            }
            {
              name = "buffer";
              option = {
                keyword_length = 3;
              };
            }
            {
              name = "path";
            }
          ];
          window = {
            completion = {
              __raw = "cmp.config.window.bordered()";
            };
            documentation = {
              __raw = "cmp.config.window.bordered()";
            };
          };
        };
      };
    };
  };
}
