local function gh(repo)
	return "https://github.com/" .. repo
end

do
	vim.pack.add({
		{ src = gh("nvim-lua/plenary.nvim") },
		{ src = gh("neovim/nvim-lspconfig") },
		{ src = gh("pmizio/typescript-tools.nvim") },
	})

	require("typescript-tools").setup({})
end
