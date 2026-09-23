local function gh(repo)
  return "https://github.com/" .. repo
end

do
  -- [[ Formatting ]]
  vim.pack.add({ gh("stevearc/conform.nvim") })

  local prettier = { "prettierd", "prettier", stop_after_first = true }

  -- External formatters per filetype. A filetype listed here is also formatted on save (see `format_on_save` below).
  -- Conform can run multiple formatters sequentially: `python = { "isort", "black" }`
  -- Use 'stop_after_first' to run only the first available formatter from the list.
  local formatters_by_ft = {
    lua = { "stylua" },
    go = { "goimports" }, -- goimports also gofmt's the file
    rust = { "rustfmt" },
    python = { "black" },
    javascript = prettier,
    javascriptreact = prettier,
    typescript = prettier,
    typescriptreact = prettier,
    sql = { "sqruff" },
    -- ["*"] = { "codespell" },
  }

  require("conform").setup({
    notify_on_error = false,
    format_on_save = function(bufnr)
      if formatters_by_ft[vim.bo[bufnr].filetype] then
        return { timeout_ms = 500 }
      end
    end,
    default_format_opts = {
      lsp_format = "fallback", -- Use external formatters if configured below, otherwise use LSP formatting. Set to `false` to disable LSP formatting entirely.
    },
    formatters_by_ft = formatters_by_ft,
  })

  vim.keymap.set({ "n", "v" }, "<leader>f", function()
    require("conform").format({ async = true })
  end, { desc = "[F]ormat buffer" })
end
