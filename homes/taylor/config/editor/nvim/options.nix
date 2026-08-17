_: {
  config = {
    opts = {
      updatetime = 100; # Faster completion
      swapfile = false; # Disable the swap file

      # Line numbers
      number = true; # Display the absolute line number of the current line
      relativenumber = true; # Relative line numbers for easy jumping

      # Visual
      showmatch = true; # Show matching brackets
      cursorline = true; # Highlight the current line
      termguicolors = true; # True color support
      signcolumn = "yes"; # Always show sign column (prevents layout shift)
      wrap = false; # Disable line wrapping
      colorcolumn = ""; # No fixed column marker

      # Splits
      splitright = true; # Vertical splits open to the right
      splitbelow = true; # Horizontal splits open below

      # Scrolling
      scrolloff = 8; # Keep 8 lines visible above/below cursor
      sidescrolloff = 8; # Keep 8 columns visible left/right of cursor

      # Clipboard
      clipboard = "unnamedplus"; # Use system clipboard

      # Tab options
      tabstop = 2; # Number of spaces a <Tab> in the text stands for (local to buffer)
      shiftwidth = 2; # Number of spaces used for each step of (auto)indent (local to buffer)
      expandtab = true; # Expand <Tab> to spaces in Insert mode (local to buffer)
      autoindent = true; # Do clever autoindenting

      # Search
      ignorecase = true; # Ignore case in search
      smartcase = true; # Override ignorecase if search has uppercase

      # Completion
      completeopt = "menu,menuone,noselect";
    };
  };
}
