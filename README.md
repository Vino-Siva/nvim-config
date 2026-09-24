# nvim-config

Customized Neovim config with [Kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim) as its base, using the
built-in `vim.pack` plugin manager (no plugin-manager plugin). Leader key is `<Space>`.

Tested on Neovim **0.12.5**. `nvim-treesitter` (main branch) requires 0.12 or later.

## Install

```sh
git clone <this repo> ~/.config/nvim          # or any name, see NVIM_APPNAME below
nvim                                          # first start installs plugins at the revisions in nvim-pack-lock.json
```

To try it without touching an existing config, clone it anywhere and use an app name:

```sh
ln -s /path/to/this/clone ~/.config/nvim-thevinsi
NVIM_APPNAME=nvim-thevinsi nvim               # plugins/state go to ~/.local/share/nvim-thevinsi etc.
```

### Prerequisites

| Needed for | Tools |
|------------|-------|
| Plugin install, treesitter parsers | `git`, `curl`, `tar`, a C compiler, [`tree-sitter-cli`](https://github.com/tree-sitter/tree-sitter) ≥ 0.26.1 (from your package manager, not npm) |
| Telescope | `make` (builds `telescope-fzf-native`), `ripgrep` (live grep); `fd` optional |
| Mason-installed tools | `unzip`, `curl`; `node`/`npm` (prettierd, markdownlint, LSPs), `go` (goimports, gopls, delve), `python3`/`pip` (black) |
| Formatting Rust | `rustfmt` (from rustup; not a Mason package) |
| Clipboard (`clipboard=unnamedplus`) | `wl-clipboard` (Wayland) or `xclip`/`xsel` (X11) |
| Icons (`have_nerd_font = true`) | a [Nerd Font](https://www.nerdfonts.com/) selected in your terminal |

## Layout

```
init.lua                    -> require("thevinsi")
lua/thevinsi/
  init.lua                  requires options, remap, pack (in that order)
  options.lua               leader key, editor options
  remap.lua                 general keymaps, diagnostics config, basic autocmds
  pack.lua                  PackChanged hook: build steps after plugin install/update
plugin/*.lua                one file per plugin (install + setup + its keymaps)
after/ftplugin/lua.lua      per-filetype overrides (Lua: 2 spaces)
nvim-pack-lock.json         exact plugin revisions (managed by vim.pack; commit it)
stylua.toml                 Lua style: 2 spaces, width 120
docs/cleanup-log.md         reference log of the 2026-09 cleanup (what changed and why)
```

**Load order:** Neovim runs `init.lua` first, which loads `thevinsi.options` (sets the leader key), `thevinsi.remap` and
`thevinsi.pack` (registers the build hook). Then it sources every `plugin/*.lua` file in alphabetical order. Each of those
calls `vim.pack.add(...)` and configures its plugin. Keep each file self-contained (add the plugins it needs itself, as
`neo-tree.lua` does with its dependencies) rather than relying on alphabetical order.

## Plugins

| Area | Plugins |
|------|---------|
| Colors / UI | `rose-pine` (transparent background), `mini.nvim` (statusline, icons, `ai`, `surround`), `which-key`, `indent-blankline`, `todo-comments`, `fidget` |
| Navigation | `telescope` (+ `fzf-native`, `ui-select`), `neo-tree` (`\`) |
| LSP / completion | `nvim-lspconfig`, `mason` (+ `mason-lspconfig`, `mason-tool-installer`), `blink.cmp`, `LuaSnip` + `friendly-snippets`, `typescript-tools` |
| Syntax | `nvim-treesitter` (main branch, parsers auto-installed on first use), `nvim-treesitter-context` (pins the current function/class signature at the top of the window), `nvim-treesitter-textobjects` (function/class jumps and text objects) |
| Format / lint | `conform` (format on save for filetypes listed in `formatters_by_ft`), `nvim-lint` (markdown) |
| Git | `gitsigns` |
| Debugging | `nvim-dap`, `nvim-dap-ui`, `nvim-dap-go` |
| Editing | `nvim-autopairs`, `guess-indent` |
| Misc | `vim-be-good` |

Language servers enabled in `plugin/lsp-config.lua`: `clangd`, `gopls`, `pyright`, `rust_analyzer`, `bashls`, `html`,
`cssls`, `jsonls`, `lua_ls`, `tailwindcss`, `yamlls`, `stylua` (LSP mode). TypeScript is handled by `typescript-tools`.

## Key mappings (leader = `<Space>`)

Press `<Space>` and wait: which-key shows what is available. Highlights:

| Keys | Action |
|------|--------|
| `<leader>sf` / `sg` / `sw` / `sh` / `sk` | Telescope: files / live grep / word under cursor / help / keymaps |
| `<leader><leader>` / `<leader>/` | Telescope: open buffers / fuzzy search in current buffer |
| `\` | Neo-tree reveal / close |
| `grr` `gri` `grd` `grt` `gO` `gW` | LSP pickers: references, implementations, definitions, type definitions, symbols |
| `grn` `gra` `grD` (and `<leader>ca`) | Rename, code action, declaration |
| `<leader>f` | Format buffer (conform) |
| `<leader>X` / `<space>x` | Source current file / run current line or selection as Lua |
| `<leader>d` (normal, visual) / `<leader>p` (visual) | Delete / paste over a selection without overwriting the clipboard (black-hole register) |
| `<leader>h…` / `]c` `[c` | Git hunks (gitsigns) |
| `[x` / `<leader>tc` | Jump to the pinned function signature / toggle it (treesitter-context) |
| `]f` `[f` `]F` `[F` / `]k` `[k` `]K` `[K` | Next / previous function start and end / same for classes (treesitter-textobjects) |
| `aF` `iF` / `ak` `ik` | Select around / inside a function / class (`af`/`if` stay mini.ai's function *calls*) |
| `<leader>tu` | Toggle the undo tree (Neovim's built-in `nvim.undotree`; jump between undo branches) |
| `<F5>` `<F1>` `<F2>` `<F3>` `<leader>b` | Debugger: continue, step into/over/out, breakpoint |
| `<leader>ot` | Open a terminal at the bottom (`<Esc><Esc>` leaves terminal mode) |
| `<C-h/j/k/l>` | Move between windows |

## Maintenance

- Update plugins: `:lua vim.pack.update()`, review, confirm, then commit the changed `nvim-pack-lock.json`.
- Inspect pending updates without applying: `:lua vim.pack.update(nil, { offline = true })`.
- Format Lua: `stylua .` (2 spaces, width 120, configured in `stylua.toml`); format-on-save does this for Lua buffers.
- Mason tools (`ensure_installed` in `plugin/lsp-config.lua`) are installed by `mason-tool-installer` after startup in an
  interactive session; in a headless run use `:MasonToolsInstallSync`.
- Smoke test: `NVIM_APPNAME=<name> nvim --headless "+qa"` should print no errors.

See [`docs/cleanup-log.md`](docs/cleanup-log.md) for the history of the recent cleanup, including each step's reasoning,
verification and how to revert it.
