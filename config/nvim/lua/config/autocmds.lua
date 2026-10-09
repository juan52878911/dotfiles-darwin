-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

-- macOS 26+ enforces code signing on .so/.dylib files loaded via dlopen.
-- Re-sign all native libs after every Lazy install/update so they don't get
-- killed with SIGKILL (Code Signature Invalid). Requires no certificate —
-- an ad-hoc signature (`-`) is enough for the local system.
local function resign_native_libs()
  local data_dir = vim.fn.stdpath("data")
  vim.fn.jobstart({
    "find", data_dir, "(", "-name", "*.so", "-o", "-name", "*.dylib", ")", "-exec",
    "codesign", "--force", "--sign", "-", "{}", ";",
  }, {
    on_exit = function(_, code)
      if code == 0 then
        vim.notify("Native libs re-signed for macOS", vim.log.levels.INFO, { title = "codesign" })
      end
    end,
  })
end

-- Re-sign after Lazy plugin operations
vim.api.nvim_create_autocmd("User", {
  pattern = { "LazyInstall", "LazyUpdate", "LazySync", "LazyRestore" },
  callback = resign_native_libs,
})

-- Re-sign after Mason tool installs (LSPs, formatters, linters)
vim.api.nvim_create_autocmd("User", {
  pattern = { "MasonToolInstallComplete" },
  callback = resign_native_libs,
})

-- Manual command for ad-hoc re-signing
vim.api.nvim_create_user_command("ReSignLibs", resign_native_libs, { desc = "Re-sign native .so/.dylib for macOS" })

-- Nvim ocioso en segundo plano: pausar los timers de alta frecuencia sin foco.
-- Medido (2026-10-09): cada nvim parado gastaba ~0,7% de un núcleo sin hacer
-- nada, también en sesiones de tmux sin cliente. ~0,30% es el updater de noice
-- (un defer_fn cada 33 ms, para siempre) y ~0,25% los timers de 50 ms de snacks
-- (statuscolumn y notifier). Sin ellos el consumo ocioso medido es 0,00%.
-- tmux reenvía el foco (focus-events on): al cambiar de pane, ventana o sesión
-- llega FocusLost, y al volver FocusGained, que lo reanuda todo antes de que
-- se note. Lo que se pierde: un nvim VISIBLE pero sin foco (split al lado) no
-- refresca signos ni mensajes de noice hasta que vuelves a él.
local pausa = vim.api.nvim_create_augroup("PausaSinFoco", { clear = true })
local pausados, noice_pausado = {}, false

vim.api.nvim_create_autocmd("FocusLost", {
  group = pausa,
  callback = function()
    vim.uv.walk(function(h)
      if h:get_type() == "timer" and h:is_active() and not h:is_closing() then
        local rep = h:get_repeat()
        if rep > 0 and rep <= 50 then
          h:stop()
          table.insert(pausados, h)
        end
      end
    end)
    local ok, router = pcall(require, "noice.message.router")
    if ok and router._updater then
      router._updater.stop()
      router._updater = nil -- enable() solo crea uno nuevo si es nil
      noice_pausado = true
    end
  end,
})

vim.api.nvim_create_autocmd("FocusGained", {
  group = pausa,
  callback = function()
    for _, h in ipairs(pausados) do
      if not h:is_closing() then
        h:again()
      end
    end
    pausados = {}
    if noice_pausado then
      noice_pausado = false
      pcall(function() require("noice.message.router").enable() end)
    end
  end,
})
