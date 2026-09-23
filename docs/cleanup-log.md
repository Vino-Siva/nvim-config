# Cleanup log

Reference for the config cleanup started 2026-09-23. Every step is **one commit**, and each commit appends its own
entry below, so `git revert <sha>` removes the code change and its log entry together.

- Branch: `cleanup`, developed in a git worktree so the live `main` checkout is never modified while working.
- Baseline: commits `62eddcd`, `1156bdd`, `1cf0e8e` (pre-existing work), `3683aa2` (this log's first version).
  These were committed on `main` before the branch was created.
- Neovim: 0.12.5. Plugin manager: built-in `vim.pack`.
- Stylua: Mason's `stylua` (in the `nvim-vinsi` app's Mason directory, `~/.local/share/nvim-vinsi/mason/bin/stylua`), not on
  `PATH`. During the cleanup a copy from Omarchy's default Mason directory was used (see step 5). Style: 2 spaces, width 120.

## Testing setup

This repo is run as `NVIM_APPNAME=nvim-vinsi` (`~/.config/nvim-vinsi` is a symlink to the `main` checkout, which is in daily
use). `~/.config/nvim` is Omarchy's stock LazyVim config and is not used. So the `cleanup` branch was exercised from its
worktree through a separate, throwaway app name:

```sh
git worktree add <dir> -b cleanup                        # already done; <dir> is a folder inside the main checkout
ln -s <dir> ~/.config/nvim-thevinsi                      # one-time; `git worktree list` shows <dir>
NVIM_APPNAME=nvim-thevinsi nvim                         # run this config
NVIM_APPNAME=nvim-thevinsi nvim --headless "+qa"        # smoke test: should print no errors
```

Plugins install into `~/.local/share/nvim-thevinsi`, so the other config is untouched. To undo:
`rm ~/.config/nvim-thevinsi` and `rm -r ~/.local/share/nvim-thevinsi ~/.local/state/nvim-thevinsi ~/.cache/nvim-thevinsi`.

## Entry template

```
### Step N — title
- Finding:
- Files:
- Change:
- Why:
- Verify: command -> expected result
- Revert: git revert <sha> (+ caveats)
```

## Findings → steps

| # | Finding | Step |
|---|---------|------|
| 1 | `after/plugins/vim-be-good.lua` is in a directory Neovim never loads, and calls a nonexistent `setup()` | 1 |
| 2 | `after/ftplugin/all.lua` never runs (no `all` filetype) | 2 |
| 3 | `TermOpen` autocmd uses global `vim.opt`, so later windows lose line numbers | 3 |
| 4 | `<leader><leader>` (buffers) is a prefix of `<space><space>x`, causing a `timeoutlen` delay | 4 |
| 5 | Stylua default (tabs) conflicts with `ftplugin/lua.lua` (2 spaces); repo has mixed indentation | 5, 6 |
| 6 | Format-on-save enabled for python/go/sql but `black`/`goimports`/`sqruff` not installed; errors are silent | 7 |
| 7 | `enabled_filetypes` duplicates `formatters_by_ft`; `gofmt` redundant after `goimports` | 8 |
| 8 | Leader and indent options set in several places | 9 |
| 9 | `updatetime = 50` fires `CursorHold` requests constantly | 10 |
| 10 | `have_nerd_font = false` while devicons are in use | 11 |
| 11 | Plugins split between `plugin/` and `lua/thevinsi/plugins/`; stale gitsigns comment | 12 |
| 12 | Stale which-key groups (`<leader>d`, `r`, `w`) | 13 |
| 13 | `grd` mapped in both `lsp-config.lua` and `telescope.lua` | 14 |
| 14 | `<leader>y`/`<leader>Y` redundant with `clipboard=unnamedplus` | 15 |
| 15 | LuaSnip loaded with no snippets | 16 |
| 16 | `nvim-pack-lock.json` gitignored (not reproducible) | 17 |
| 17 | README is a single line | 18 |
| 18 | Undo dir, `<leader>ca` overlap, eager DAP, ts tooling, lua_ls library, `LspDetach` augroup | not changing (see below) |

## Keymap changes

| Keymap | Before | After | Step |
|--------|--------|-------|------|
| Source current file (normal) | `<space><space>x` | `<leader>X` (with description) | 4 |
| `grd` (buffer-local, LSP attached) | defined twice (lsp-config + telescope; telescope won) | defined once, in telescope (same behaviour) | 14 |
| Yank to system clipboard (normal/visual) | `<leader>y` → `"+y` | removed; use plain `y` (`clipboard=unnamedplus`) | 15 |
| Yank to end of line to clipboard (normal) | `<leader>Y` → `"+Y` | removed; use plain `Y` | 15 |

## Steps

<!-- Step entries are appended below, one per commit. -->

### Step 1 — document removal of dead `after/plugins/vim-be-good.lua`
- Finding: #1.
- Files: `docs/cleanup-log.md` only. `after/plugins/vim-be-good.lua` is untracked, so it does not exist on this branch.
- Change: none in code. **Manual action after merging into `main`:** delete the leftover untracked directory from the
  main checkout (`rm -r after/plugins`); it was left in place on purpose because `main` is in use.
- Why: Neovim only sources `after/plugin/` (singular), so it never ran. Had it run, `require("ThePrimeagen/vim-be-good")`
  would have errored (vim-be-good is a Vimscript plugin with no Lua module or `setup()`), and `vim.pack.add` there duplicated
  the install already done in `lua/thevinsi/plugins/vim-be-good.lua`.
- Deleted content, for reference:
  ```lua
  vim.pack.add("https://github.com/ThePrimeagen/vim-be-good.git")
  require("ThePrimeagen/vim-be-good").setup({})
  ```
- Verify: on the branch, `ls after` shows only `ftplugin`; `NVIM_APPNAME=nvim-thevinsi nvim --headless "+qa"` prints no errors.
- Revert: nothing to revert in git (file was untracked); recreate from the block above if ever wanted (not recommended).

### Step 2 — remove ineffective `after/ftplugin/all.lua`
- Finding: #2.
- Files: `after/ftplugin/all.lua` (deleted), `docs/cleanup-log.md`.
- Change: deleted the file. Its content was `expandtab` + `tabstop/shiftwidth/softtabstop = 4`.
- Why: ftplugin files are sourced by filetype name (`after/ftplugin/<filetype>.lua`); there is no filetype called
  `all`, so it never ran. The same 4-space defaults are already set globally in root `init.lua` (consolidated in
  step 9), and `guess-indent.nvim` overrides indentation per file anyway.
- Verify: `git ls-files after` lists only `after/ftplugin/lua.lua`; `NVIM_APPNAME=nvim-thevinsi nvim --headless "+qa"`
  prints no errors. No behaviour change expected.
- Revert: `git revert <sha>`.

### Step 3 — scope terminal number settings with `opt_local`
- Finding: #3.
- Files: `lua/thevinsi/remap.lua` (`TermOpen` autocmd), `docs/cleanup-log.md`.
- Change: `vim.opt.number/relativenumber = false` → `vim.opt_local.number/relativenumber = false`.
- Why: `vim.opt` behaves like `:set`, which changes the global default as well as the current window. After opening a
  terminal, every window created later inherited "no line numbers". `opt_local` (`:setlocal`) affects only the terminal window.
- Verify: `NVIM_APPNAME=nvim-thevinsi nvim --headless "+term" "+new" "+lua print(vim.wo.number)" "+qa!"`
  → before: `false` (bug), after: `true`. The terminal window itself still prints `false`.
- Revert: `git revert <sha>`.

### Step 4 — free `<leader><leader>` from a `timeoutlen` collision
- Finding: #4.
- Files: `lua/thevinsi/remap.lua`, `docs/cleanup-log.md`.
- Change: normal-mode "source current file" moved from `<space><space>x` to `<leader>X`, and given a `desc`.
  `<space>x` (run current line) and the visual `<space>x` (run selection) are unchanged.
- Why: with `<leader>` = space, `<leader><leader>` (Telescope buffers, in `plugin/telescope.lua`) was a strict prefix of
  `<space><space>x`. Neovim therefore waited `timeoutlen` (300 ms) after the second space to see if `x` followed, adding
  a delay every time the buffer picker was opened. `<leader>X` is not a prefix of anything and nothing else maps it.
- Verify: `NVIM_APPNAME=nvim-thevinsi nvim --headless` and list normal-mode maps starting with two spaces →
  before: `"  "` (buffers) and `"  x"` (source); after: only `"  "` (buffers). `maparg('<leader>X','n')` is non-empty.
- Revert: `git revert <sha>`; muscle memory note: the old key was `<space><space>x`.

### Step 5 — add `stylua.toml`
- Finding: #5.
- Files: `stylua.toml` (new), `docs/cleanup-log.md`.
- Change: `indent_type = "Spaces"`, `indent_width = 2`, `column_width = 120` (same values as the `stylua.toml` in Omarchy's stock `~/.config/nvim`).
- Why: with no config, stylua defaults to **tabs**, but `after/ftplugin/lua.lua` says 2 spaces. Every format-on-save on a
  Lua file (`conform.nvim` → `stylua`) therefore rewrote indentation to tabs, which produced the whole-file diffs seen in the
  baseline commits and left the repo with mixed tab / 2-space files. conform's stylua formatter finds this file by walking up
  from the buffer, so it now formats consistently with the ftplugin.
- Verify: `stylua --check .` now reports differences in 21 files (all are the indentation mismatch left over from before);
  they are fixed mechanically in step 6. No runtime behaviour changes in this step.
- Tooling note: the Mason copy in Omarchy's default data directory (`~/.local/share/nvim/mason/packages/stylua/stylua`,
  v2.5.2) has lost its executable bit, so the cleanup ran a copy of it from a scratch directory. That directory belongs to the
  stock config, not to `nvim-vinsi`: the `stylua` in `~/.local/share/nvim-vinsi/mason/` is installed and executable (checked
  after the merge), so nothing needs fixing for this config.
- Revert: `git revert <sha>`.

### Step 6 — run stylua over the repo
- Finding: #5.
- Files: 21 Lua files under `lua/` and `plugin/` (`git show --stat <sha>`), `docs/cleanup-log.md`.
- Change: `stylua .` with the step-5 config. Formatting only: tabs → 2 spaces, plus stylua's normal quote/paren/wrapping rules.
- Why: gets the whole repo to one style so later steps produce small diffs and future format-on-save runs are no-ops.
- Verify:
  - `stylua --check .` → clean.
  - Logic is unchanged: for every tracked `*.lua` file, the stripped bytecode (`string.dump(loadfile(f), true)`) of the
    pre-format version equals the post-format version (25/25 files identical), and a deliberately different pair is flagged.
    Compare both versions **in the same process**: LuaJIT serialises table-constructor keys in a per-process hash order, so
    dumps from two separate `nvim -l` runs of the same file can differ byte-for-byte.
  - `NVIM_APPNAME=nvim-thevinsi nvim --headless "+qa"` prints no errors.
- Revert: `git revert <sha>` (whole-repo formatting revert; later steps' diffs would then conflict, so revert in reverse order).
- Tip: to keep `git blame` useful, add this commit to `.git-blame-ignore-revs` and run
  `git config blame.ignoreRevsFile .git-blame-ignore-revs` (not done automatically).

### Step 7 — install the formatters conform uses
- Finding: #6.
- Files: `plugin/lsp-config.lua` (`ensure_installed`), `docs/cleanup-log.md`.
- Change: added `black`, `goimports`, `sqruff` (Mason package names confirmed in the local mason-registry) next to the
  existing `prettierd`, `stylua`, `markdownlint-cli2`.
- Why: `plugin/conform.lua` enables format-on-save for python, go, sql (and others) but only `stylua` and `prettierd` were
  ever requested from Mason. `conform` is configured with `notify_on_error = false`, so a missing formatter fails silently.
  `rustfmt` (rustup component) and `gofmt` (Go toolchain) are not Mason packages and were already on `PATH`.
  `goimports` builds with Go and `black` installs with pip, so both need those toolchains (present on this machine).
- Verify: in the sandbox, `conform.get_formatter_info(name).available` for `stylua black goimports gofmt rustfmt prettierd sqruff`
  → before: `false` for stylua/black/goimports/prettierd/sqruff (gofmt/rustfmt `true`); after `:MasonToolsInstallSync`: all `true`.
  Note: `mason-tool-installer` runs on `VimEnter`, so in normal use the tools appear after the first start; in a
  headless test run `:MasonToolsInstallSync` explicitly.
- Revert: `git revert <sha>` (installed binaries stay in Mason's directory; remove with `:MasonUninstall black goimports sqruff`).

### Step 8 — derive `format_on_save` from `formatters_by_ft`
- Finding: #7.
- Files: `plugin/conform.lua`, `docs/cleanup-log.md`.
- Change:
  - `formatters_by_ft` is now a local table, and `format_on_save` formats any filetype that appears in it
    (previously a separate `enabled_filetypes` table had to be kept in sync by hand).
  - `go = { "goimports", "gofmt" }` → `{ "goimports" }` (goimports already applies gofmt formatting).
  - Added `javascriptreact` (`.jsx`) with the same prettierd → prettier chain as the other JS filetypes.
  - The repeated prettier chain is one `prettier` local.
- Why: one list to maintain, and it can no longer drift (e.g. adding a formatter but forgetting to enable format-on-save).
- Behaviour notes: filetypes formatted on save are unchanged apart from the new `javascriptreact`. Filetypes without an
  entry (markdown, json, css, html, yaml, …) still are not formatted on save; `<leader>f` still formats manually
  (falling back to LSP formatting via `lsp_format = "fallback"`).
- Verify (sandbox, headless `nvim file +write`, unformatted input files): `.py` (black), `.go` (goimports), `.ts`, `.jsx`,
  `.lua` (stylua) are rewritten; `.md` is left unchanged. `.js` is formatted too, but the very first save after a cold
  `prettierd` start can exceed the 500 ms `timeout_ms` and silently skip formatting (pre-existing; raise `timeout_ms` if it bothers you).
- Revert: `git revert <sha>`.

### Step 9 — set leader and indent options in one place
- Finding: #8.
- Files: `init.lua`, `lua/thevinsi/options.lua`, `lua/thevinsi/remap.lua`, `docs/cleanup-log.md`.
- Change:
  - Leader/localleader were set in `init.lua`, `options.lua` and `remap.lua`; now only in `options.lua`.
  - `guicursor`, `expandtab`, `tabstop`, `shiftwidth`, `softtabstop`, `smartindent` moved from `init.lua` into `options.lua`
    (values unchanged, commented).
  - Root `init.lua` is now just `require("thevinsi")`.
- Why: one source of truth per setting. Ordering is preserved: `lua/thevinsi/init.lua` requires `options` first (leader is
  set before `remap`, `pack`, and all `plugin/*` files, which Neovim sources after `init.lua`).
- Verify (sandbox, headless): effective `leader`, `localleader`, `guicursor`, `expandtab`, `tabstop`, `shiftwidth`,
  `softtabstop`, `smartindent` for a no-filetype buffer, a `lua` buffer and a `python` buffer are identical before and
  after (`ts=4` / `ts=2` for lua / `ts=4`). `<leader>sf` and `<leader>X` are still mapped.
- Revert: `git revert <sha>`.

### Step 10 — relax `updatetime` from 50 to 250
- Finding: #9.
- Files: `lua/thevinsi/options.lua`, `docs/cleanup-log.md`.
- Change: `vim.o.updatetime = 50` → `250` (Kickstart's default), comment explains why.
- Why: `updatetime` is the idle time before `CursorHold` fires. `plugin/lsp-config.lua` uses `CursorHold`/`CursorHoldI` to send
  `textDocument/documentHighlight` requests, so at 50 ms a request went out after nearly every brief pause while typing or
  reading. 250 ms still feels immediate but sends far fewer requests. It also sets how often swap files are written.
- Verify: `nvim --headless "+lua print(vim.o.updatetime)"` → `250`.
- Revert: `git revert <sha>`; or set it back to `50` if you preferred the snappier highlight.

### Step 11 — enable the Nerd Font flag
- Finding: #10.
- Files: `lua/thevinsi/options.lua`, `docs/cleanup-log.md`.
- Change: `vim.g.have_nerd_font = false` → `true`.
- Why: neo-tree was given `nvim-web-devicons` (needs a Nerd Font) while the flag said no font was available, so mini.nvim
  (`mini.icons`, statusline icons) and which-key kept plain text. JetBrainsMono Nerd Font is installed and configured in the
  terminal configs, so icons render.
- What changes visually: mini.statusline shows icons, which-key shows mapping icons, and `mini.icons` is set up and mocks
  `nvim-web-devicons` (`MiniIcons.mock_nvim_web_devicons()`), which Telescope/neo-tree then use.
- Note: `plugin/mini.lua` is sourced before `plugin/neo-tree.lua`, so neo-tree gets the mini mock rather than the real
  `nvim-web-devicons` it installs. That works (checked below); the explicit `nvim-web-devicons` entry in `neo-tree.lua`
  is now redundant but harmless, and left alone.
- Verify (sandbox): `vim.g.have_nerd_font` is `true`, `MiniIcons` is a table, `require("nvim-web-devicons").get_icon("x.lua", "lua")`
  returns an icon, and `:Neotree show` opens a window without errors.
- Revert: `git revert <sha>` (or open the config in a terminal without a Nerd Font → boxes/`?` glyphs are the symptom to look for).

### Step 12 — move gitsigns and vim-be-good into `plugin/`
- Finding: #11.
- Files: `lua/thevinsi/plugins/gitsigns.lua` → `plugin/gitsigns.lua` (`git mv`, history kept),
  `lua/thevinsi/plugins/vim-be-good.lua` → `plugin/vim-be-good.lua`, `lua/thevinsi/init.lua`, `docs/cleanup-log.md`.
- Change:
  - Both plugins now live in `plugin/` like every other plugin, which Neovim sources automatically after `init.lua`.
    The `require("thevinsi.plugins.*")` lines in `lua/thevinsi/init.lua` and the empty `lua/thevinsi/plugins/` directory are gone.
  - `gitsigns.lua`: removed the duplicated header line and the stale note ("already included in init.lua") which was
    Kickstart text that no longer described this repo.
  - `vim-be-good.lua`: dropped the commented-out `setup()` (it is a Vimscript plugin, there is nothing to set up) and added
    a one-line description.
- Why: one convention for plugins. `lua/thevinsi/` now only holds core modules (`options`, `remap`, `pack`).
  `pack.lua` (the `PackChanged` build hook) is still required from `init.lua`, so it is registered before any
  `vim.pack.add` in `plugin/*` runs.
- Load-order note: `gitsigns` used to be set up during `init.lua`; it is now set up in `plugin/*` alphabetical order (after
  `debug.lua`). It has no dependency on other plugins, so nothing observable changes.
- Verify (sandbox, headless, open a file inside the git repo): `:Gitsigns` and `:VimBeGood` exist, the buffer-local
  `<leader>hp` and `]c` mappings exist, and gitsigns is attached — same result before and after.
- Revert: `git revert <sha>`.

### Step 13 — remove stale which-key groups
- Finding: #12.
- Files: `plugin/which-key.lua`, `docs/cleanup-log.md`.
- Change: removed the `<leader>d` ("Document"), `<leader>r` ("Rename") and `<leader>w` ("Workspace") group labels.
  Kept `<leader>c`, `<leader>s`, `<leader>t`, `<leader>h` and `gr`.
- Why: they were Kickstart leftovers with nothing under them. `<leader>r` and `<leader>w` have no mappings anywhere, and
  `<leader>d` is actually your own `"_d` (delete without yanking) mapping, which a "Document" group label misdescribed.
  `<leader>t` and `<leader>h` look empty globally but are buffer-local (LSP inlay hints, gitsigns), so those groups stay.
- Verify: `grep -rE '"<leader>[rwd]' plugin lua` only finds the two `<leader>d` delete maps in `remap.lua`;
  `require("which-key.config").options.spec` now lists c, s, t, h, gr.
- Revert: `git revert <sha>`.

### Step 14 — remove duplicate `grd` mapping
- Finding: #13.
- Files: `plugin/lsp-config.lua`, `docs/cleanup-log.md`.
- Change: deleted `map("grd", vim.lsp.buf.definition, ...)` from the `LspAttach` handler and left a note pointing to
  `plugin/telescope.lua`, where `grd` (and `grr`, `gri`, `grt`, `gO`, `gW`) are mapped to Telescope pickers.
- Why: two `LspAttach` autocmds set the same buffer-local key. They run in plugin load order (`lsp-config.lua` before
  `telescope.lua`), so the Telescope one always overwrote it and the `lsp-config.lua` one was dead code.
- Verify (sandbox, open a Lua file so `lua_ls` attaches): `maparg('grd','n',false,true).desc` is `[G]oto [D]efinition`
  (the Telescope mapping; the removed one was `LSP: [G]oto [d]efinition`) both before and after.
- Side finding, no change needed: a second client `stylua --lsp` attaches to Lua buffers. That is the `stylua = {}` entry
  in the `servers` table: stylua 2.x has an LSP mode and nvim-lspconfig ships a config for it.
- Revert: `git revert <sha>`.

### Step 15 — drop redundant `<leader>y` / `<leader>Y`
- Finding: #14.
- Files: `lua/thevinsi/remap.lua`, `docs/cleanup-log.md`.
- Change: removed `<leader>y` (normal + visual, `"+y`) and `<leader>Y` (`"+Y`), with a comment explaining why. `<leader>p`
  (`"_dP`, paste without overwriting the register) and `<leader>d` (`"_d`, delete without yanking) are kept.
- Why: `options.lua` sets `clipboard = "unnamedplus"`, so every plain `y`/`Y` already writes to the system clipboard; these
  maps did exactly the same thing. (`d` also writes to the clipboard under `unnamedplus`, which is why `<leader>d` is still useful.)
- Verify (sandbox, headless, waiting for the async provider): before and after, a plain `yy` puts the line in the `+` register
  (and `wl-paste` returns it). `maparg('<leader>y')`/`('<leader>Y')` → mapped before, unmapped after; `<leader>d`/`<leader>p` still mapped.
- Muscle-memory note: `<Space>y` now moves right one character and starts a plain `y` operator instead of yanking to the clipboard;
  use `y` directly. If you would rather keep the old habit, `git revert <sha>` restores it.
- Revert: `git revert <sha>`.

### Step 16 — enable friendly-snippets
- Finding: #15.
- Files: `plugin/luasnip.lua`, `docs/cleanup-log.md`.
- Change: `vim.pack.add({ gh("rafamadriz/friendly-snippets") })` and `require("luasnip.loaders.from_vscode").lazy_load()`
  (previously both lines were commented out). New plugin: `rafamadriz/friendly-snippets`.
- Why: `blink.cmp` is configured with `snippets = { preset = "luasnip" }` and `sources.default` includes `"snippets"`, and LuaSnip
  was installed and set up, but no snippets were ever loaded, so the whole snippet path did nothing. friendly-snippets is
  the standard collection; `lazy_load()` only loads snippets for filetypes you actually open.
- Verify (sandbox, open a `typescript` buffer, count `require("luasnip").get_snippets(ft)`):
  before `typescript=0 all=0`; after `typescript=30 all=9`. (`lua`/`python` stay 0 until a buffer of that type is opened.)
  Snippets then appear in the blink.cmp menu with the `snippets` source; accept with `<c-y>` (blink "default" preset) and jump
  with `<Tab>`/`<S-Tab>`. Not verified in a live UI.
- Alternative not taken: dropping LuaSnip and using blink's built-in snippet engine (`snippets.preset = "default"`).
- Revert: `git revert <sha>` (the cloned plugin stays in `~/.local/share/nvim*/site/pack/core/opt`; `:lua vim.pack.del({"friendly-snippets"})` removes it).

### Step 17 — track `nvim-pack-lock.json`
- Finding: #16.
- Files: `.gitignore` (deleted, its only line was `nvim-pack-lock.json`), `nvim-pack-lock.json` (new, 33 plugins), `docs/cleanup-log.md`.
- Change: stopped ignoring the `vim.pack` lockfile and committed it. Before committing it I pruned six plugins from it that this
  config never declares or references: `aether.nvim`, `kanagawa.nvim`, `lumon.nvim`, `matteblack.nvim`, `nightfox.nvim`,
  `retro-82.nvim` (color-scheme plugins left over from earlier experiments / other branch state), using
  `:lua vim.pack.del({...})` in the sandbox. `friendly-snippets` (step 16) is in it.
- Why: the lockfile is what pins each plugin to an exact commit (`rev`), so a fresh clone installs the same versions instead of
  whatever is newest that day. It contains only `src` and `rev` — no machine-specific paths. Earlier history shows it was
  deliberately ignored (`Delete nvim-pack-lock.json`, `update: .gitignore`); the cost of tracking it is that every
  `vim.pack.update()` now shows up as a diff (which is also the point: updates become reviewable and revertible).
- Verify: `git ls-files nvim-pack-lock.json` lists it; it has 33 entries and none of the six themes; a fresh install from
  it (see below) leaves it unchanged.
- **Merge caution:** the `main` checkout has its own untracked `nvim-pack-lock.json` (39 entries, includes the six themes).
  Git will refuse to merge over it. Before merging `cleanup` into `main`, move it aside
  (`mv nvim-pack-lock.json nvim-pack-lock.json.bak`); after the merge, the tracked file is used.
- Revert: `git revert <sha>` (restores the ignore rule and untracks the file; the local file stays on disk).

### Step 18 — expand the README
- Finding: #17.
- Files: `README.md`, `docs/cleanup-log.md`.
- Change: replaced the one-line README with install / `NVIM_APPNAME` instructions, a prerequisites table, the repo layout,
  the load order, a plugin overview, a key-mapping cheat sheet, maintenance commands, and a link to this log.
- Why: the repo had no description of how it is structured or what it needs (`tree-sitter-cli`, a C compiler, `ripgrep`,
  `make`, a clipboard tool, a Nerd Font, `go`/`node`/`python3` for some Mason packages).
- Verify: prerequisites were checked against `nvim-treesitter`'s own README (Neovim ≥ 0.12, `tar`, `curl`, `tree-sitter-cli`
  ≥ 0.26.1, C compiler) and the tools present on this machine; every path in the layout block exists in the tree; the LSP server
  list matches the `servers` table; the key table matches the live mappings.
- Revert: `git revert <sha>`.

### Step 19 — finalize this log
- Files: `docs/cleanup-log.md`.
- Change: filled in the sections below (commit index, final verification, merge instructions, deliberately-not-changed list,
  sandbox cleanup). Docs only.
- Revert: `git revert <sha>`.

## Commit index

| Step | Commit | Subject |
|------|--------|---------|
| 0a | `62eddcd` `1156bdd` `1cf0e8e` | pre-existing WIP, committed on `main` before branching |
| 0b | `3683aa2` | docs: add cleanup log (on `main`, before branching) |
| 1 | `ebe00c5` | docs: log removal of dead after/plugins/vim-be-good.lua |
| 2 | `029461c` | fix: remove ineffective after/ftplugin/all.lua |
| 3 | `ad181be` | fix: scope terminal number settings with opt_local |
| 4 | `ef37eae` | fix: free <leader><leader> from timeoutlen collision |
| 5 | `04912e2` | chore: add stylua.toml (2 spaces, width 120) |
| 6 | `a0a3efe` | style: run stylua over repo |
| 7 | `eec0189` | fix: install formatters used by conform via mason |
| 8 | `5387895` | refactor: derive conform format_on_save from formatters_by_ft |
| 9 | `be22b3e` | refactor: set leader and indent options in one place |
| 10 | `54ed77e` | fix: relax updatetime from 50 to 250 |
| 11 | `8a7da3c` | chore: enable nerd font support |
| 12 | `504e20d` | refactor: move gitsigns and vim-be-good into plugin/ |
| 13 | `e3ce4b5` | chore: remove stale which-key groups |
| 14 | `0e41d8d` | fix: remove duplicate grd mapping from lsp-config |
| 15 | `fadb6e1` | chore: drop redundant <leader>y and <leader>Y maps |
| 16 | `7905792` | feat: enable friendly-snippets for LuaSnip |
| 17 | `8c178db` | chore: track nvim-pack-lock.json |
| 18 | `ad95c48` | docs: expand README |
| 19 | (this commit) | docs: finalize cleanup log |

List them any time with `git log --oneline 2a4e475..cleanup` (`2a4e475` is the last commit before the cleanup).

## Final verification (branch `cleanup`, sandbox `NVIM_APPNAME=nvim-thevinsi`)

- `stylua --check .` → clean.
- Fresh headless start prints no errors.
- A brand-new install from the tracked lockfile (second sandbox) installed 33 plugins, all at their locked revision, and left
  `nvim-pack-lock.json` unchanged.
- Every formatter in `formatters_by_ft` is available except the `prettier` fallback (`prettierd` comes first in the chain and
  is installed, so this has no effect).
- Each step's own check is recorded in its entry above. Not verified: interactive UI behaviour (blink.cmp menu, which-key
  popup rendering, icons in the statusline); the checks were headless.

## Merging into `main`

`main` is the config in daily use, so nothing was changed there except the three baseline commits and the log commit (`3683aa2`).
Do this from the main checkout when you are ready:

```sh
cd ~/Projects/nvim-config
git status                                   # expect only the untracked leftovers below
rm -r after/plugins                          # leftover dead dir from step 1 (untracked)
mv nvim-pack-lock.json nvim-pack-lock.json.bak   # step 17: git refuses to overwrite an untracked lockfile
git merge cleanup                            # fast-forward if main has not moved since 3683aa2
nvim                                         # first start: installs friendly-snippets, mason tools (black, goimports, sqruff)
```

Afterwards (optional): `git worktree remove <dir> && git branch -d cleanup` (`git worktree list` shows `<dir>`), and remove
the worktree folder's line that was added to `.git/info/exclude`. The old themes that were in your previous lockfile stay installed on disk
(inactive); remove them with `:lua vim.pack.del({"aether.nvim","kanagawa.nvim","lumon.nvim","matteblack.nvim","nightfox.nvim","retro-82.nvim"})`.
Keymap changes to relearn are listed in the table near the top (`<leader>X`, no `<leader>y`/`<leader>Y`).

## Sandbox cleanup

The testing sandboxes used during the cleanup can be removed once you no longer need them:

```sh
rm ~/.config/nvim-thevinsi ~/.config/nvim-thevinsi-fresh                  # symlinks to the worktree
rm -r ~/.local/share/nvim-thevinsi* ~/.local/state/nvim-thevinsi* ~/.cache/nvim-thevinsi*
```

## Deliberately not changed

Reviewed, judged not worth changing now (or a matter of taste). Revisit later if wanted.

| Item | Why left alone |
|------|----------------|
| `undodir = ~/.vim/undodir` in `options.lua` | Removing it would orphan the existing undo history there (124 files, 3.9 MB at the time of writing); Neovim's default undo dir would start empty. |
| `<leader>ca` (global) overlapping `gra` (buffer-local, LSP) | You added `<leader>ca` on purpose. Downside: it errors on buffers without an LSP client. |
| DAP stack loads eagerly (`plugin/debug.lua`: nvim-dap, dap-ui, nio, dap-go, mason-nvim-dap) and is Go/delve-only | Startup cost is modest and it is your debugging setup; lazy-load or trim when you know which languages you debug. |
| `typescript-tools.nvim` instead of `ts_ls`/`vtsls` | Works; switching is a preference and a behaviour change. |
| `lua_ls` `workspace.library = vim.api.nvim_get_runtime_file("", true)` | Known-slow (the comment in the file says so) but gives full completion for your own config. `lazydev.nvim` is the usual replacement. |
| `kickstart-lsp-detach` augroup created with `clear = true` inside each `LspAttach` | Upstream Kickstart quirk: each new attach clears earlier buffers' detach handlers. Low impact. |
| `nvim-web-devicons` explicitly added in `neo-tree.lua` | Redundant now that mini's mock is used (step 11) but harmless. |
| Format-on-save only for filetypes in `formatters_by_ft` (none for json/css/html/yaml/markdown) and `timeout_ms = 500` | A choice, not a bug; `<leader>f` formats any buffer. Cold `prettierd` start can exceed 500 ms once. |
| `prettier` (the fallback after `prettierd`) is not in Mason `ensure_installed` | Not needed while `prettierd` is installed. |
| Mason's `stylua` in `~/.local/share/nvim/mason/` (Omarchy's stock config, not `nvim-vinsi`) lost its executable bit | Not used by this config; `nvim-vinsi`'s own Mason `stylua` is installed and executable. |
| Mixed `vim.o` / `vim.opt` usage, literal `<space>x` vs `<leader>`, `kickstart-*` augroup names | Cosmetic. |
