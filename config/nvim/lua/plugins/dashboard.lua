-- Dashboard de inicio (2026-08-18).
-- El wordmark es "asccilabs": tu propia marca, que además lleva "ascii" dentro.
-- Generado con figlet en la fuente colossal. Para cambiarlo:
--   figlet -f colossal "loquesea"
-- Otras fuentes que quedan bien en terminal: epic, block, slant, univers, larry3d.
return {
  "folke/snacks.nvim",
  opts = {
    dashboard = {
      preset = {
        header = [==[
                                d8b888        888
                                Y8P888        888
                                   888        888
 8888b. .d8888b  .d8888b .d8888b888888 8888b. 88888b. .d8888b
    "88b88K     d88P"   d88P"   888888    "88b888 "88b88K
.d888888"Y8888b.888     888     888888.d888888888  888"Y8888b.
888  888     X88Y88b.   Y88b.   888888888  888888 d88P     X88
"Y888888 88888P' "Y8888P "Y8888P888888"Y88888888888P"  88888P'

   the terminal is the interface
]==],
      },
      sections = {
        { section = "header" },
        { section = "keys", gap = 1, padding = 1 },
        { section = "startup" },
      },
    },
  },
}
