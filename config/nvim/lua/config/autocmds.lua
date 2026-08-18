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
