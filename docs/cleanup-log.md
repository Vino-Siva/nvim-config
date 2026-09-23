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

## Deliberately not changed

_Filled in at the final step._
