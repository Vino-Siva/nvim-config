-- Built-in undo tree viewer (bundled with Neovim >= 0.12 as an optional package)
vim.cmd.packadd("nvim.undotree")

vim.keymap.set("n", "<leader>tu", "<cmd>Undotree<CR>", { desc = "[T]oggle [u]ndo tree" })
