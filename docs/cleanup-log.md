# Cleanup log

Reference for the config cleanup started 2026-09-23. Every step is **one commit**, and each commit appends its own
entry below, so `git revert <sha>` removes the code change and its log entry together.

- Branch: `cleanup`, developed in a git worktree so the live `main` checkout is never modified while working.
- Baseline: commits `62eddcd`, `1156bdd`, `1cf0e8e` (pre-existing work), `3683aa2` (this log's first version).
  These were committed on `main` before the branch was created.
- Neovim: 0.12.5. Plugin manager: built-in `vim.pack`.
- Stylua: `~/.local/share/nvim/mason/bin/stylua` (not on `PATH`). Style: 2 spaces, width 120.

## Testing setup

`~/.config/nvim` is a different config and the `main` checkout is in daily use, so the `cleanup` branch is exercised
from its worktree through a separate app name:

```sh
git worktree add .claude/worktrees/cleanup -b cleanup   # already done; from the main checkout
ln -s ~/Projects/nvim-config/.claude/worktrees/cleanup ~/.config/nvim-thevinsi   # one-time
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
- Change: `indent_type = "Spaces"`, `indent_width = 2`, `column_width = 120` (same values as the LazyVim config's `stylua.toml`).
- Why: with no config, stylua defaults to **tabs**, but `after/ftplugin/lua.lua` says 2 spaces. Every format-on-save on a
  Lua file (`conform.nvim` → `stylua`) therefore rewrote indentation to tabs, which produced the whole-file diffs seen in the
  baseline commits and left the repo with mixed tab / 2-space files. conform's stylua formatter finds this file by walking up
  from the buffer, so it now formats consistently with the ftplugin.
- Verify: `stylua --check .` now reports differences in 21 files (all are the indentation mismatch left over from before);
  they are fixed mechanically in step 6. No runtime behaviour changes in this step.
- Tooling note: the Mason copy at `~/.local/share/nvim/mason/packages/stylua/stylua` (v2.5.2) has lost its executable bit,
  so the cleanup ran a copy of it from a scratch directory. If `:ConformInfo` shows stylua as not executable in the LazyVim
  setup, run `chmod +x` on that file (or `:MasonInstall stylua` in this config's sandbox / normal setup).
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

## Deliberately not changed

_Filled in at the final step._
