return {
  'nvim-neo-tree/neo-tree.nvim',
  branch = 'v3.x',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-tree/nvim-web-devicons',
    'MunifTanjim/nui.nvim',
  },
  -- 使用快捷键懒加载
  keys = {
    { '<leader>e', ':Neotree toggle<CR>', desc = 'NeoTree Toggle' },
  },
  config = function()
    require('neo-tree').setup {
      window = {
        position = 'left',
        width = 25, -- 你喜欢的宽度
      },
      filesystem = {
        follow_current_file = { enabled = true },
      },
    }
  end,
}
