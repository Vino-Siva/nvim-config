-- Treesitter-aware function/class text objects and jumps
-- NOTE: mini.ai already owns `af`/`if` (function *calls*), so whole-function objects use `aF`/`iF`.
vim.pack.add({ { src = "https://github.com/nvim-treesitter/nvim-treesitter-textobjects", version = "main" } })

require("nvim-treesitter-textobjects").setup({
  select = {
    lookahead = true, -- jump forward to the next match if the cursor is not inside one
    selection_modes = {
      ["@function.outer"] = "V", -- select whole functions linewise so `daF` removes the lines cleanly
    },
  },
  move = { set_jumps = true }, -- record jumps so <C-o> returns to where you were
})

local select = require("nvim-treesitter-textobjects.select")
local move = require("nvim-treesitter-textobjects.move")

-- Select: aF/iF = around/inside function, ak/ik = around/inside class
local objects = {
  { "F", "@function.outer", "@function.inner", "function" },
  { "k", "@class.outer", "@class.inner", "class" },
}
for _, obj in ipairs(objects) do
  local key, outer, inner, name = unpack(obj)
  vim.keymap.set({ "x", "o" }, "a" .. key, function()
    select.select_textobject(outer, "textobjects")
  end, { desc = "Around " .. name })
  vim.keymap.set({ "x", "o" }, "i" .. key, function()
    select.select_textobject(inner, "textobjects")
  end, { desc = "Inside " .. name })
end

-- Move: ]f/[f = next/previous function start, ]F/[F = next/previous function end (same for k = class)
local moves = {
  { "f", "@function.outer", "function" },
  { "k", "@class.outer", "class" },
}
for _, obj in ipairs(moves) do
  local key, query, name = unpack(obj)
  local upper = key:upper()
  vim.keymap.set({ "n", "x", "o" }, "]" .. key, function()
    move.goto_next_start(query, "textobjects")
  end, { desc = "Next " .. name .. " start" })
  vim.keymap.set({ "n", "x", "o" }, "[" .. key, function()
    move.goto_previous_start(query, "textobjects")
  end, { desc = "Previous " .. name .. " start" })
  vim.keymap.set({ "n", "x", "o" }, "]" .. upper, function()
    move.goto_next_end(query, "textobjects")
  end, { desc = "Next " .. name .. " end" })
  vim.keymap.set({ "n", "x", "o" }, "[" .. upper, function()
    move.goto_previous_end(query, "textobjects")
  end, { desc = "Previous " .. name .. " end" })
end
