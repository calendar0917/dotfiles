return {
  {
    'folke/tokyonight.nvim',
    priority = 1000, -- 确保主题最先加载
    config = function()
      require('tokyonight').setup {
        styles = {
          comments = { italic = false },
        },
      }
      vim.cmd.colorscheme 'tokyonight-night'
    end,
  },
}
