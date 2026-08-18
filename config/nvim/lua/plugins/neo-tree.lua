-- neo-tree: ancho fijo y menos ruido (2026-08-18)
-- Antes truncaba nombres (`achieve`, `educati`) porque el ancho variaba según el
-- estado; y mostraba carpetas de build y contadores de elementos ocultos.
return {
  "nvim-neo-tree/neo-tree.nvim",
  opts = {
    window = {
      width = 34,               -- fijo: los nombres dejan de recortarse
      auto_expand_width = false, -- que no varíe entre estados
    },
    filesystem = {
      group_empty_dirs = true,
      filtered_items = {
        visible = false,
        show_hidden_count = false, -- fuera los "(18 hidden items)" al final de cada carpeta
        hide_gitignored = true,
        hide_dotfiles = false,
        hide_by_name = {
          "font",         -- TTFs que nunca se abren desde el árbol
          "build",
          "graphify-out", -- salida de build, sale con ? en cada archivo
          "node_modules",
          ".venv",
        },
        never_show = { ".git", "__pycache__", ".DS_Store" },
      },
    },
    -- Sin "(18 hidden items)" al final de cada carpeta
    default_component_configs = {
      file_size = { enabled = false },
      type = { enabled = false },
      last_modified = { enabled = false },
      created = { enabled = false },
    },
  },
}
