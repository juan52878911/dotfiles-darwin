-- Node.js para el provider de Neovim: el de Homebrew o el más reciente de nvm,
-- sin lanzar `node --version` en cada arranque (lo hacía config/nodejs.lua).
do
  local cands = { "/opt/homebrew/bin/node" }
  local nvm = vim.fn.glob(vim.fn.expand("~/.nvm/versions/node/*/bin/node"), false, true)
  table.sort(nvm, function(a, b) return vim.version.lt(a:match("v([%d.]+)") or "0", b:match("v([%d.]+)") or "0") == false end)
  vim.list_extend(cands, nvm)
  for _, p in ipairs(cands) do
    if vim.fn.executable(p) == 1 then
      vim.g.node_host_prog = p
      break
    end
  end
end

-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")
vim.opt.timeoutlen = 1000
vim.opt.ttimeoutlen = 50
