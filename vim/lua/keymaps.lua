--" 选中即复制 mouse selection
--" https://github.com/OneOfOne/dotfiles/blob/1082fb7c7752867793a51b04763f79b7347c466f/.config/nvim/lua/config/keymaps.lua#L62-L65
--" https://www.reddit.com/r/neovim/comments/171p7z3/comment/k3s5nlx/

local function vmap(keys, fn, desc)
    vim.keymap.set('v', keys, fn, { desc = desc, noremap = true })
end

vmap('<LeftRelease>', '"*ygv', 'yank on mouse selection')
--vmap('<LeftRelease>', '"*ygv<esc>', 'yank selection to *')
vmap('<S-LeftRelease>', '<LeftRelease>', '')
vmap('<S-RightRelease>', '"*dgv<esc>', 'delete selection to *')
vmap('<C-LeftRelease>', '"*P', 'replace selection with *')
