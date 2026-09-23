vim.pack.add({
  {
    src = "https://github.com/rose-pine/neovim",
    name = "rose-pine",
  },
})
require("rose-pine").setup({ disable_background = true })
vim.cmd("colorscheme rose-pine")
-- vim.cmd("colorscheme rose-pine-moon")
