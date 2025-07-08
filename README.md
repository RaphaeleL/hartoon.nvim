# Hartoon

A Harpoon-inspired Neovim plugin for managing and jumping to your favorite tmux sessions, with Telescope integration and an editable popup UI.

## Features

- Pin the current tmux session to a persistent list
- Edit pinned sessions in a floating, editable popup window
- Jump to any pinned session with a single function or keymap
- Telescope picker for all tmux sessions
- All actions use `tms -c <session>` to switch sessions

## Installation

Add to your Neovim plugin manager (example for lazy.nvim):

```lua
{
    -- https://github.com/RaphaeleL/tms needs to be installed
    'RaphaeleL/hartoon.nvim',
    dependencies = {
        'nvim-lua/plenary.nvim',
        'nvim-telescope/telescope.nvim',
        'nvim-telescope/telescope-fzf-native.nvim',
    },
    config = function()
        require('hartoon').setup()
    end,
    keys = {
        { '<leader>ht', '<cmd>HartoonTmuxSessions<cr>', desc = 'List tmux sessions' },
        { '<leader>hta', '<cmd>HartoonPinTmuxSession<cr>', desc = 'Pin current tmux session' },
        { '<leader>htm', '<cmd>HartoonEditPinnedTmux<cr>', desc = 'Edit pinned tmux sessions' },
        { '<leader>ta', '<cmd>HartooJumpTo1<cr>', desc = 'Jump to pinned tmux session 1' },
        { '<leader>ts', '<cmd>HartoonJumpTo2<cr>', desc = 'Jump to pinned tmux session 2' },
        { '<leader>td', '<cmd>HartoonJumpTo3<cr>', desc = 'Jump to pinned tmux session 3' },
    },
}
```

## Usage

### Pin the current tmux session

- Keymap: `<leader>hta`
- Command: `:HartoonPinTmuxSession`

### Edit pinned sessions

- Keymap: `<leader>htm`
- Command: `:HartoonEditPinnedTmux`
- In the popup: Edit/add/delete session names, then `:w` to save. Press `<CR>` on a line to jump to that session and close the popup.

### Jump to a pinned session by index

Call from Lua or map to a key:

```lua
require('hartoon').jump(1) -- Jumps to the first pinned session
```

Example keymaps:

```lua
vim.keymap.set('n', '<leader>h1', function() require('hartoon').jump(1) end)
vim.keymap.set('n', '<leader>h2', function() require('hartoon').jump(2) end)
vim.keymap.set('n', '<leader>h3', ':HartoonJumpTo3<cr>')
```

### Telescope picker for all tmux sessions

- Command: `:HartoonTmuxSessions`

## Requirements

- [tms](https://github.com/RaphaeleL/tms) command in your PATH
- [tmux](https://github.com/tmux/tmux)
- [Telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)

## License

MIT

