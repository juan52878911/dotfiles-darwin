-- smear-cursor: estela animada al saltar el cursor. Desactivado por defecto:
-- redibuja en cada fotograma de la animación (CPU) y kitty ya tiene su propia
-- estela (cursor_trail en kitty.conf), que funciona también fuera de Neovim.
-- Para probarlo: NVIM_SMEAR=1 nvim
return {
  "sphamba/smear-cursor.nvim",
  enabled = vim.env.NVIM_SMEAR == "1",
  opts = {},
}
