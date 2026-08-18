-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- ─── Pulido visual (2026-08-17) ──────────────────────────────────────────────
-- El modo ya se ve en lualine; no hace falta repetirlo en la línea de comandos
vim.opt.showmode = false

-- Una sola columna de signos: evita que el gutter se duplique al aparecer diagnósticos
vim.opt.signcolumn = "yes:1"

-- Sin los ~ al final del buffer
vim.opt.fillchars = { eob = " " }

-- Diagnósticos fuera del flujo del texto: el virtual_text de markdownlint metía
-- avisos en medio del README. Ahora solo se despliega la línea actual (nvim 0.11+).
vim.diagnostic.config({
  virtual_text = false,
  virtual_lines = { current_line = true },
  underline = true,
  severity_sort = true,
})
