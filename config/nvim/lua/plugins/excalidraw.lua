-- Excalidraw en Neovim (kitty graphics protocol vía snacks.image)
--
-- Al abrir un `.excalidraw` (JSON) o un `.excalidraw.md` (Obsidian, json /
-- compressed-json) el buffer se muestra como imagen. Requiere:
--   ~/.local/bin/excalidraw-render  (node + @excalidraw/utils + rsvg-convert)
--   brew: imagemagick librsvg       (snacks.image usa `magick`)
--   kitty (o tmux con allow-passthrough on)
--
-- Keymaps (solo en estos buffers):
--   <leader>ix  alterna imagen ↔ fuente (JSON/markdown)
--   <leader>ir  vuelve a renderizar (ignora caché)
-- Comandos: :Excalidraw [toggle|image|source|refresh]

local RENDER = vim.fn.expand("~/.local/share/excalidraw-render/excalidraw-render.js")
local CACHE = vim.fn.stdpath("cache") .. "/excalidraw"
local uv = vim.uv or vim.loop

local X = {}
local state = {} ---@type table<number, {mode: "image"|"source", ft: string}>

local function is_excalidraw(file)
  return file:match("%.excalidraw$") ~= nil or file:match("%.excalidraw%.md$") ~= nil
end

local function cache_file(file)
  local st = uv.fs_stat(file)
  local key = vim.fn.sha256(file .. "|" .. (st and st.mtime.sec or 0) .. "|" .. vim.o.background)
  return CACHE .. "/" .. key:sub(1, 20) .. ".png"
end

---@param file string
---@param cb fun(png: string)
---@param force? boolean
function X.render(file, cb, force)
  vim.fn.mkdir(CACHE, "p")
  local png = cache_file(file)
  if not force and uv.fs_stat(png) then
    return cb(png)
  end
  local args = { "node", RENDER, file, png, "--scale", "2" }
  if vim.o.background == "dark" then
    table.insert(args, "--dark")
  end
  vim.system(args, { text = true }, function(res)
    vim.schedule(function()
      if res.code == 0 and uv.fs_stat(png) then
        cb(png)
      else
        -- quita el volcado gigante del bundle minificado que Node imprime en errores
        local err = (res.stderr or ""):gsub("[^\n]*!function[^\n]*\n?", "")
        vim.notify("excalidraw-render falló:\n" .. vim.trim(err):sub(-600), vim.log.levels.ERROR, { title = "Excalidraw" })
      end
    end)
  end)
end

function X.show_image(buf, force)
  buf = buf or vim.api.nvim_get_current_buf()
  local file = vim.api.nvim_buf_get_name(buf)
  if not is_excalidraw(file) then
    return vim.notify("No es un archivo Excalidraw", vim.log.levels.WARN, { title = "Excalidraw" })
  end
  if not Snacks.image.supports_terminal() then
    return vim.notify("El terminal no soporta kitty graphics (ver :checkhealth snacks)", vim.log.levels.WARN, { title = "Excalidraw" })
  end
  state[buf] = state[buf] or { mode = "source", ft = vim.bo[buf].filetype }
  X.render(file, function(png)
    if not vim.api.nvim_buf_is_valid(buf) then
      return
    end
    Snacks.image.buf.attach(buf, { src = png })
    state[buf].mode = "image"
  end, force)
end

function X.show_source(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  Snacks.image.placement.clean(buf)
  local st = state[buf]
  local ft = st and st.ft ~= "" and st.ft or (vim.api.nvim_buf_get_name(buf):match("%.md$") and "markdown" or "json")
  vim.bo[buf].modifiable = true
  vim.bo[buf].filetype = ft
  if st then
    st.mode = "source"
  end
end

function X.toggle(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  if state[buf] and state[buf].mode == "image" then
    X.show_source(buf)
  else
    X.show_image(buf)
  end
end

local function setup_buffer(buf)
  local map = function(lhs, fn, desc)
    vim.keymap.set("n", lhs, fn, { buffer = buf, desc = desc })
  end
  map("<leader>ix", function() X.toggle(buf) end, "Excalidraw: imagen ↔ fuente")
  map("<leader>ir", function() X.show_image(buf, true) end, "Excalidraw: re-renderizar")
  vim.api.nvim_buf_create_user_command(buf, "Excalidraw", function(o)
    local a = o.args ~= "" and o.args or "toggle"
    if a == "image" then X.show_image(buf)
    elseif a == "source" then X.show_source(buf)
    elseif a == "refresh" then X.show_image(buf, true)
    else X.toggle(buf) end
  end, { nargs = "?", complete = function() return { "toggle", "image", "source", "refresh" } end })
end

return {
  -- 1) snacks.image no viene activado en LazyVim: encenderlo
  {
    "folke/snacks.nvim",
    opts = {
      image = {
        enabled = true,
        doc = { enabled = true, inline = true, float = true, max_width = 80, max_height = 40 },
      },
    },
  },
  -- 2) autocmds para archivos Excalidraw
  {
    "folke/snacks.nvim",
    init = function()
      vim.filetype.add({ extension = { excalidraw = "json" } })
      local group = vim.api.nvim_create_augroup("excalidraw_render", { clear = true })
      vim.api.nvim_create_autocmd("BufReadPost", {
        group = group,
        pattern = { "*.excalidraw", "*.excalidraw.md" },
        callback = function(ev)
          setup_buffer(ev.buf)
          -- render automático al abrir
          vim.defer_fn(function()
            if vim.api.nvim_buf_is_valid(ev.buf) then
              X.show_image(ev.buf)
            end
          end, 50)
        end,
      })
      -- si editas la fuente y guardas, el siguiente render usa el archivo nuevo
      vim.api.nvim_create_autocmd("BufWritePost", {
        group = group,
        pattern = { "*.excalidraw", "*.excalidraw.md" },
        callback = function(ev)
          if state[ev.buf] and state[ev.buf].mode == "image" then
            X.show_image(ev.buf, true)
          end
        end,
      })
      vim.api.nvim_create_autocmd("BufWipeout", {
        group = group,
        callback = function(ev) state[ev.buf] = nil end,
      })
    end,
  },
}
