-- Dashboard de inicio (2026-08-18).
--
-- Wordmark "ASCCI LABS" en ANSI Shadow, 71 columnas — comprobado que cabe sin
-- envolverse (el límite práctico ronda las 78). Si lo cambias, mide antes:
--   awk '{ print length }' arte.txt | sort -rn | head -1
-- Sin espacios finales en las líneas: desalinean el centrado de snacks.
return {
  "folke/snacks.nvim",
  opts = {
    dashboard = {
      preset = {
        header = [==[
 █████╗ ███████╗ ██████╗ ██████╗██╗    ██╗      █████╗ ██████╗ ███████╗
██╔══██╗██╔════╝██╔════╝██╔════╝██║    ██║     ██╔══██╗██╔══██╗██╔════╝
███████║███████╗██║     ██║     ██║    ██║     ███████║██████╔╝███████╗
██╔══██║╚════██║██║     ██║     ██║    ██║     ██╔══██║██╔══██╗╚════██║
██║  ██║███████║╚██████╗╚██████╗██║    ███████╗██║  ██║██████╔╝███████║
╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚═════╝╚═╝    ╚══════╝╚═╝  ╚═╝╚═════╝ ╚══════╝

the terminal is the interface]==],
        -- Cinco entradas. New File, Config, Lazy y Lazy Extras ya son atajos del
        -- día a día y no merecen un renglón. Sin iconos: la tecla es el ancla.
        keys = {
          { key = "f", desc = "Buscar archivo",    action = ":lua Snacks.dashboard.pick('files')" },
          { key = "g", desc = "Buscar texto",      action = ":lua Snacks.dashboard.pick('live_grep')" },
          { key = "p", desc = "Proyectos",         action = ":lua Snacks.picker.projects()" },
          { key = "s", desc = "Restaurar sesión",  action = ':lua require("persistence").load()' },
          { key = "q", desc = "Salir",             action = ":qa" },
        },
      },
      sections = {
        { section = "header", padding = 1 },
        { section = "keys", gap = 0, padding = 1 },
        -- Footer: solo el tiempo. El "15/60 plugins" de serie invita a preguntarse
        -- por los otros 45, que están en carga diferida y es justo lo que se busca.
        -- OJO: la sección puede ser función, pero `text` DEBE ser tabla — snacks
        -- la indexa directamente y revienta al renderizar si es una función.
        function()
          local stats = require("lazy.stats").stats()
          local ms = math.floor(stats.startuptime * 100 + 0.5) / 100
          return {
            align = "center",
            padding = 1,
            text = { { ms .. " ms", hl = "SnacksDashboardFooter" } },
          }
        end,
        -- Columna derecha: estado, no solo menú. Necesita ~200 columnas para que
        -- se ponga al lado; por debajo de eso snacks la apila, que también vale.
        {
          pane = 2,
          title = "Git",
          section = "terminal",
          enabled = function()
            return Snacks.git.get_root() ~= nil
          end,
          cmd = "git status --short --branch --renames",
          height = 6,
          padding = 1,
          ttl = 300,
          indent = 2,
        },
        {
          pane = 2,
          title = "Recientes",
          section = "recent_files",
          limit = 5,
          padding = 1,
          indent = 2,
        },
      },
    },
  },
  init = function()
    -- Dos colores: un acento para header y teclas, gris para todo lo demás.
    -- En autocmd de ColorScheme porque catppuccin redefine los grupos al aplicarse.
    vim.api.nvim_create_autocmd("ColorScheme", {
      callback = function()
        local acento = "#89b4fa" -- Catppuccin blue
        local texto = "#a6adc8" -- subtext0
        local tenue = "#6c7086" -- overlay0
        local set = vim.api.nvim_set_hl
        set(0, "SnacksDashboardHeader", { fg = acento })
        set(0, "SnacksDashboardKey", { fg = acento, bold = true })
        set(0, "SnacksDashboardDesc", { fg = texto })
        set(0, "SnacksDashboardFile", { fg = texto })
        set(0, "SnacksDashboardIcon", { fg = tenue })
        set(0, "SnacksDashboardTitle", { fg = tenue })
        set(0, "SnacksDashboardDir", { fg = tenue })
        set(0, "SnacksDashboardSpecial", { fg = tenue })
        set(0, "SnacksDashboardFooter", { fg = tenue, italic = true })
      end,
    })
  end,
}
