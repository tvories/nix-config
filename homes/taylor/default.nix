{
  pkgs,
  lib,
  config,
  inputs,
  hostname,
  flake-packages,
  ...
}:
{
  imports = [
    ../_modules
    ./secrets
    ./hosts/${hostname}.nix
  ];
  modules = {
    editor = {
      nvim = {
        enable = true;
        package = flake-packages.${pkgs.system}.nvim;
        makeDefaultEditor = true;

      };

      vscode = {
        userSettings = lib.importJSON ./config/editor/vscode/settings.json;
        extensions = let
          inherit (inputs.nix-vscode-extensions.extensions.${pkgs.system}) vscode-marketplace;
        in
          with vscode-marketplace; [
            # Themes
            catppuccin.catppuccin-vsc
            thang-nm.catppuccin-perfect-icons
            qufiwefefwoyn.kanagawa

            # Language support
            golang.go
            hashicorp.terraform
            helm-ls.helm-ls
            jnoortheen.nix-ide
            mrmlnc.vscode-json5
            ms-azuretools.vscode-docker
            ms-python.python
            redhat.ansible
            redhat.vscode-yaml
            tamasfe.even-better-toml
            ms-vscode.powershell
            puppet.puppet-vscode

            # Formatters
            esbenp.prettier-vscode

            # Linters
            davidanson.vscode-markdownlint
            fnando.linter

            # Remote development
            ms-vscode-remote.remote-containers
            ms-vscode-remote.remote-ssh

            # Other
            eamodio.gitlens
            gruntfuggly.todo-tree
            ionutvmi.path-autocomplete
            luisfontes19.vscode-swissknife
            ms-kubernetes-tools.vscode-kubernetes-tools
            shipitsmarter.sops-edit
            gitlab.gitlab-workflow
            github.copilot
            oderwat.indent-rainbow
            johnpapa.vscode-peacock
            aaron-bond.better-comments
          ];
      };
    };

    security = {
      ssh = {
        enable = true;
        matchBlocks = {
          "nas3.mcbadass.local" = {
            forwardAgent = true;
            port = 22;
            user = "taylor";
            extraOptions = {
              "IdentityAgent" = "\"~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock\"";
            };
          };
          "tback.mcbadass.local" = {
            port = 22;
            user = "taylor";
            extraOptions = {
              "IdentityAgent" = "\"~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock\"";
            };
            forwardAgent = true;
          };
          "bitbucket.davita.com" = {
            user = "git";
            port = 22;
            identityFile = "~/.ssh/mac-bitbucket";
          };
          "github.com" = {
            user = "git";
            port = 22;
            extraOptions = {
              "IdentityAgent" = "\"~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock\"";
            };
          };
          "nas-vm.mcbadass.local" = {
            port = 22;
            user = "root";
            extraOptions = {
              "IdentityAgent" = "\"~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock\"";
            };
            forwardAgent = true;
          };
        };
      };
    };

    shell = {
      fish.enable = true;

    };
    shell = {
      gcloud = {
        enable = true;
      };
      go-task.enable = true;
    };
    themes = {
      catppuccin = {
        enable = true;
        flavor = "macchiato";
      };
    };
  };
}
