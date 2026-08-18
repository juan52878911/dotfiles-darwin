-- Catppuccin Mocha, unificado con tmux y kitty (2026-08-17).
-- Antes había cinco colorschemes instalados y solo se usaba uno; `oldworld.nvim`
-- además tenía lazy = false, así que se cargaba en cada arranque sin usarse.
-- El respaldo del archivo anterior está en ~/.config-backup-*/nvim/
return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    opts = {
      flavour = "mocha",
      transparent_background = false, -- opaco: la transparencia dejaba ver texto de otro panel bajo neo-tree
      term_colors = true,
      styles = {
        comments = { "italic" },
        conditionals = { "italic" },
        keywords = { "italic" },
      },
      integrations = {
        blink_cmp = true,
        fzf = true,
        gitsigns = true,
        harpoon = true,
        mason = true,
        native_lsp = { enabled = true, underlines = { errors = { "undercurl" } } },
        neotree = true,
        noice = true,
        notify = true,
        snacks = true,
        treesitter = true,
        which_key = true,
      },
      custom_highlights = function(colors)
        -- Bordes suaves; el fondo ya es sólido, no se fuerza "none" en flotantes
        return {
          FloatBorder = { fg = colors.surface2 },
          FloatTitle = { fg = colors.mauve },
        }
      end,
    },
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "catppuccin",
    },
  },
}
