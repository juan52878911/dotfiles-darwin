-- smear-cursor: estela animada al saltar el cursor dentro de Neovim. Es la
-- animación que se nota (la de kitty, cursor_trail, apenas se ve en comparación).
-- Activado; para apagarlo en una sesión concreta: NVIM_SMEAR=0 nvim
return {
  "sphamba/smear-cursor.nvim",
  enabled = vim.env.NVIM_SMEAR ~= "0",
  opts = {},
}
