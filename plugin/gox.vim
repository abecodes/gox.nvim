if !has('nvim-0.5')
  echohl WarningMsg
  echom "gox.nvim needs Neovim >= 0.5"
  echohl None
  finish
endif

if exists('g:loaded_gox') | finish | endif " prevent loading file twice

let g:loaded_gox = 1

