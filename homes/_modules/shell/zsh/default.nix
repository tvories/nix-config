{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.modules.shell.zsh;
in
{
  options.modules.shell.zsh = {
    enable = lib.mkEnableOption "zsh";
  };

  config = lib.mkIf cfg.enable {
    # Convenience alias to launch zsh from fish without it exec'ing back into fish
    programs.fish.shellAliases.tryzsh = "FISH_RUNNING=1 command zsh";

    programs.zsh = {
      enable = true;
      dotDir = "${config.xdg.configHome}/zsh";

      # Fish-like autosuggestions (gray ghost text as you type)
      autosuggestion = {
        enable = true;
        strategy = [
          "history"
          "completion"
        ];
      };

      # Fish-like syntax highlighting (valid commands green, invalid red)
      syntaxHighlighting = {
        enable = true;
        highlighters = [
          "main"
          "brackets"
          "pattern"
          "cursor"
        ];
      };

      # Fish-like history substring search (Up/Down to search matching history)
      historySubstringSearch = {
        enable = true;
        searchUpKey = [
          "^[[A"
          "^[OA"
        ];
        searchDownKey = [
          "^[[B"
          "^[OB"
        ];
      };

      enableCompletion = true;

      history = {
        size = 50000;
        save = 50000;
        ignoreDups = true;
        ignoreAllDups = true;
        ignoreSpace = true;
        extended = true;
        share = true;
      };

      plugins = [
        # Additional completion definitions
        {
          name = "zsh-completions";
          src = pkgs.zsh-completions;
        }
        # Reminds you of existing aliases (like fish abbreviation hints)
        {
          name = "zsh-you-should-use";
          src = pkgs.zsh-you-should-use;
          file = "share/zsh/plugins/you-should-use/you-should-use.plugin.zsh";
        }
        # Auto-close brackets, quotes, parens (like nvim-autopairs for your shell)
        {
          name = "zsh-autopair";
          src = pkgs.zsh-autopair;
          file = "share/zsh/zsh-autopair/autopair.zsh";
        }
        # Desktop notifications when long-running commands finish (like fish done plugin)
        {
          name = "zsh-notify";
          src = pkgs.fetchFromGitHub {
            owner = "marzocchi";
            repo = "zsh-notify";
            rev = "9c1dac81a48ec85d742ebf236172b4d92aab2f3f";
            hash = "sha256-ovmnl+V1B7J/yav0ep4qVqlZOD3Ex8sfrkC92dXPLFI=";
          };
        }
      ];

      initContent = ''
        # ── Fish-like completion styling ──────────────────────────────────
        # Menu-driven completion with highlighting (like fish tab completion)
        zstyle ':completion:*' menu select
        zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' # Case-insensitive
        zstyle ':completion:*' list-colors "''${(s.:.)LS_COLORS}"  # Colored completions
        zstyle ':completion:*' special-dirs true
        zstyle ':completion:*:descriptions' format '%F{yellow}-- %d --%f'
        zstyle ':completion:*:messages' format '%F{purple}-- %d --%f'
        zstyle ':completion:*:warnings' format '%F{red}-- no matches --%f'
        zstyle ':completion:*' group-name '''

        # Shift-Tab to go backward in completion menu
        bindkey '^[[Z' reverse-menu-complete

        # ── Fish-like directory navigation ────────────────────────────────
        setopt AUTO_CD              # Type directory name to cd into it
        setopt AUTO_PUSHD           # Push directories onto the stack
        setopt PUSHD_IGNORE_DUPS    # Don't push duplicates
        setopt PUSHD_SILENT         # Don't print stack after pushd/popd

        # ── Fish-like behavior ────────────────────────────────────────────
        setopt INTERACTIVE_COMMENTS # Allow comments in interactive shell
        setopt NO_BEEP              # No beep on error
        setopt GLOB_DOTS            # Include dotfiles in globbing (like fish)
        setopt CORRECT              # Suggest corrections for mistyped commands

        # Accept autosuggestion with Ctrl+F or End key (like fish)
        bindkey '^F' autosuggest-accept
        bindkey '^[[F' autosuggest-accept

        # Accept partial autosuggestion with Alt+F (like fish forward-word)
        bindkey '^[f' forward-word

        # ── zsh-notify ────────────────────────────────────────────────────
        # Notify after commands that take longer than 30 seconds
        zstyle ':notify:*' command-complete-timeout 30
        zstyle ':notify:*' error-title "⛔ Command failed"
        zstyle ':notify:*' success-title "✅ Command finished"
      '';
    };
  };
}
