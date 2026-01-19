return {
  "MeanderingProgrammer/render-markdown.nvim",
  dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-mini/mini.nvim" },
  ft = { "markdown", "obsidian" }, -- 确保在这些文件类型下开启
  config = function()
    require("render-markdown").setup({
      -- 配合 obsidian.nvim 的设置
      anti_conceal = { enabled = true }, -- 建议关闭，避免光标所在行跳动
      checkbox = {
        enabled = true,
        -- 这里可以自定义复选框样式
      },
    })
  end,
}
