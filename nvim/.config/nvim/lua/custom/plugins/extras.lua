return {
  -- 打字练习游戏 (懒加载：只在输入命令时加载)
  {
    'ThePrimeagen/vim-be-good',
    cmd = 'VimBeGood',
  },

  -- 代码注释高亮 (TODO, FIXME 等)
  {
    'folke/todo-comments.nvim',
    event = 'VimEnter',
    dependencies = { 'nvim-lua/plenary.nvim' },
    opts = { signs = false },
  },
}
