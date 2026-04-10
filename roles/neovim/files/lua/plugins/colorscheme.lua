return {
  {
    "rose-pine/neovim",
    name = "rose-pine",
    priority = 1000,
    opts = {
      variant = "main",
      styles = {
        transparency = true,
        italic = false,
      },
    },
    config = function(_, opts)
      require("rose-pine").setup(opts)
    end,
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "rose-pine",
    },
  },
}
