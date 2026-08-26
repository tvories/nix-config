_:
{
  config = {
    plugins.lsp = {
      enable = true;
      keymaps = {
        lspBuf = {
          "K" = "hover";
          "gd" = "definition";
          "gD" = "declaration";
          "gi" = "implementation";
          "go" = "type_definition";
          "gr" = "references";
          "gs" = "signature_help";
          "<leader>rn" = "rename";
          "<leader>ca" = "code_action";
        };
        diagnostic = {
          "<leader>e" = "open_float";
          "[d" = "goto_prev";
          "]d" = "goto_next";
          "<leader>q" = "setloclist";
        };
      };
      servers = {
        nixd.enable = true;
        gopls.enable = true;
        terraformls.enable = true;
        jsonls.enable = true;
        yamlls = {
          enable = true;
          settings = {
            yaml = {
              schemas = {
                kubernetes = "/*.yaml";
              };
              schemaStore = {
                enable = true;
              };
            };
          };
        };
        marksman.enable = true;
        lua_ls = {
          enable = true;
          settings = {
            Lua = {
              diagnostics = {
                globals = [ "vim" ];
              };
              workspace = {
                checkThirdParty = false;
              };
            };
          };
        };
        bashls.enable = true;
      };
    };

    plugins.trouble = {
      enable = true;
      settings = {
        auto_close = true;
        use_diagnostic_signs = true;
      };
    };

    keymaps = [
      {
        mode = "n";
        key = "<leader>xx";
        action = "<cmd>Trouble diagnostics toggle<cr>";
        options = {
          desc = "Diagnostics (Trouble)";
        };
      }
      {
        mode = "n";
        key = "<leader>xb";
        action = "<cmd>Trouble diagnostics toggle filter.buf=0<cr>";
        options = {
          desc = "Buffer Diagnostics (Trouble)";
        };
      }
    ];
  };
}
