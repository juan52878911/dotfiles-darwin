return {
  "MeanderingProgrammer/render-markdown.nvim",
  dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-mini/mini.nvim" }, -- if you use the mini.nvim suite
  ---@module 'render-markdown'
  ---@type render.md.UserConfig
  opts = {
    -- Headings sobrios (2026-08-17): antes cada nivel llevaba círculo numerado,
    -- signo en el gutter y barra de fondo completa. Ahora el fondo queda solo en
    -- H1 y los demás niveles se distinguen por color y negrita.
    heading = {
      enabled = true,
      sign = false,
      icons = {},
      width = "block",
      left_pad = 0,
      backgrounds = { "RenderMarkdownH1Bg" },
    },
    bullet = {
      enabled = true,
      icons = { "●", "○", "◆", "◇" },
      right_pad = 1,
      highlight = "render-markdownBullet",
    },
  },
}
