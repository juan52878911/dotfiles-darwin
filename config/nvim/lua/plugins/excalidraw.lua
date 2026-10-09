-- Excalidraw en Neovim (kitty graphics protocol vía snacks.image)
--
-- Al abrir un `.excalidraw` (JSON) o `.excalidraw.md` (Obsidian, json /
-- compressed-json) se muestra el diagrama en un visor flotante CENTRADO,
-- con los colores originales de Excalidraw y un indicador de carga.
-- Requiere:
--   ~/.local/bin/excalidraw-render  (node + @excalidraw/utils + rsvg-convert)
--   brew: imagemagick librsvg       (snacks.image usa `magick`)
--   kitty (o tmux con allow-passthrough on)
--
-- En el buffer fuente:
--   <leader>ix  abrir/cerrar el visor       <leader>ir  re-renderizar
-- Dentro del visor:
--   + / =  acercar    -  alejar    0  tamaño inicial
--   r  re-renderizar  s  ver fuente (cierra el visor)   q / <Esc>  cerrar
-- Comandos: :Excalidraw [toggle|image|source|refresh]

local RENDER = vim.fn.expand("~/.local/share/excalidraw-render/excalidraw-render.js")
local CACHE = vim.fn.stdpath("cache") .. "/excalidraw"
local uv = vim.uv or vim.loop

local X = {}
-- un visor por buffer fuente
local viewers = {} ---@type table<number, {win?: number, buf?: number, png?: string, zoom: number, spinner?: number}>

local function is_excalidraw(file)
  return file:match("%.excalidraw$") ~= nil or file:match("%.excalidraw%.md$") ~= nil
end

local function cache_file(file)
  local st = uv.fs_stat(file)
  local key = vim.fn.sha256(file .. "|" .. (st and st.mtime.sec or 0) .. "|" .. vim.o.background)
  return CACHE .. "/" .. key:sub(1, 20) .. ".png"
end

-- Dimensiones de un PNG leyendo el IHDR (sin dependencias)
local function png_size(file)
  local fd = io.open(file, "rb")
  if not fd then
    return nil
  end
  local head = fd:read(24)
  fd:close()
  if not head or #head < 24 or head:sub(13, 16) ~= "IHDR" then
    return nil
  end
  -- big-endian a mano: string.unpack no existe en LuaJIT (Lua 5.1)
  local function be32(str, i)
    local a, b, c, d = str:byte(i, i + 3)
    return ((a * 256 + b) * 256 + c) * 256 + d
  end
  return { width = be32(head, 17), height = be32(head, 21) }
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
  local cmd = { "node", RENDER, file, png, "--scale", "2" }
  if vim.o.background == "dark" then
    table.insert(cmd, "--dark") -- modo oscuro de Excalidraw (mismo filtro que la app)
  end
  vim.system(cmd, { text = true }, function(res)
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

-- Geometría del float: centrado, respetando el aspect ratio del PNG
local function win_geometry(png, zoom)
  local cols, lines = vim.o.columns, vim.o.lines - 2
  local max_w, max_h = math.floor(cols * 0.9), math.floor(lines * 0.9)
  local dim = png and png_size(png)
  local w, h = max_w, max_h
  if dim and dim.width > 0 and dim.height > 0 then
    -- tamaño de celda del terminal (px) para convertir la imagen a celdas
    local ok, term = pcall(function()
      return require("snacks.image.terminal").size()
    end)
    local cell_w = ok and term and term.cell_width or 8
    local cell_h = ok and term and term.cell_height or 16
    local img_w = dim.width / cell_w
    local img_h = dim.height / cell_h
    local fit = math.min(max_w / img_w, max_h / img_h)
    w = math.max(20, math.min(max_w, math.floor(img_w * fit * zoom + 0.5)))
    h = math.max(5, math.min(max_h, math.floor(img_h * fit * zoom + 0.5)))
  end
  return {
    relative = "editor",
    width = w,
    height = h,
    col = math.floor((cols - w) / 2),
    row = math.floor((lines - h) / 2),
    style = "minimal",
    border = "rounded",
    title = " Excalidraw ",
    title_pos = "center",
  }
end

local function viewer_valid(v)
  return v and v.win and vim.api.nvim_win_is_valid(v.win)
end

function X.close(src_buf)
  local v = viewers[src_buf]
  if not v then
    return
  end
  if v.spinner then
    v.spinner = nil
  end
  if v.buf and vim.api.nvim_buf_is_valid(v.buf) then
    pcall(Snacks.image.placement.clean, v.buf)
  end
  if viewer_valid(v) then
    pcall(vim.api.nvim_win_close, v.win, true)
  end
  if v.buf and vim.api.nvim_buf_is_valid(v.buf) then
    pcall(vim.api.nvim_buf_delete, v.buf, { force = true })
  end
  viewers[src_buf] = nil
end

local function set_zoom(src_buf, zoom)
  local v = viewers[src_buf]
  if not viewer_valid(v) or not v.png then
    return
  end
  v.zoom = math.min(3, math.max(0.3, zoom))
  vim.api.nvim_win_set_config(v.win, win_geometry(v.png, v.zoom))
end

local SPIN = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }

local function show_loading(v)
  v.spinner = 0
  local function tick()
    if not v.spinner or not viewer_valid(v) or not vim.api.nvim_buf_is_valid(v.buf) then
      return
    end
    v.spinner = v.spinner + 1
    local h = vim.api.nvim_win_get_height(v.win)
    local w = vim.api.nvim_win_get_width(v.win)
    local msg = SPIN[(v.spinner % #SPIN) + 1] .. " Renderizando diagrama…"
    local pad_top = math.max(0, math.floor(h / 2) - 1)
    local lines = {}
    for _ = 1, pad_top do
      lines[#lines + 1] = ""
    end
    lines[#lines + 1] = string.rep(" ", math.max(0, math.floor((w - vim.fn.strdisplaywidth(msg)) / 2))) .. msg
    vim.bo[v.buf].modifiable = true
    vim.api.nvim_buf_set_lines(v.buf, 0, -1, false, lines)
    vim.bo[v.buf].modifiable = false
    vim.defer_fn(tick, 80)
  end
  tick()
end

local function viewer_keymaps(src_buf, vbuf)
  local map = function(lhs, fn, desc)
    vim.keymap.set("n", lhs, fn, { buffer = vbuf, nowait = true, desc = desc })
  end
  map("q", function() X.close(src_buf) end, "Cerrar visor")
  map("<Esc>", function() X.close(src_buf) end, "Cerrar visor")
  map("+", function() set_zoom(src_buf, (viewers[src_buf] or {}).zoom * 1.25) end, "Acercar")
  map("=", function() set_zoom(src_buf, (viewers[src_buf] or {}).zoom * 1.25) end, "Acercar")
  map("-", function() set_zoom(src_buf, (viewers[src_buf] or {}).zoom / 1.25) end, "Alejar")
  map("0", function() set_zoom(src_buf, 1) end, "Tamaño inicial")
  map("r", function() X.show_image(src_buf, true) end, "Re-renderizar")
  map("s", function() X.close(src_buf) end, "Ver fuente")
end

function X.show_image(src_buf, force)
  src_buf = src_buf or vim.api.nvim_get_current_buf()
  local file = vim.api.nvim_buf_get_name(src_buf)
  if not is_excalidraw(file) then
    return vim.notify("No es un archivo Excalidraw", vim.log.levels.WARN, { title = "Excalidraw" })
  end
  if not Snacks.image.supports_terminal() then
    return vim.notify("El terminal no soporta kitty graphics (ver :checkhealth snacks)", vim.log.levels.WARN, { title = "Excalidraw" })
  end

  local v = viewers[src_buf]
  if not viewer_valid(v) then
    X.close(src_buf) -- limpia restos si el win murió
    v = { zoom = 1 }
    viewers[src_buf] = v
    v.buf = vim.api.nvim_create_buf(false, true)
    vim.bo[v.buf].bufhidden = "wipe"
    v.win = vim.api.nvim_open_win(v.buf, true, win_geometry(nil, 1))
    vim.wo[v.win].winhighlight = "NormalFloat:Normal"
    viewer_keymaps(src_buf, v.buf)
    -- cerrar el visor si se abandona la ventana
    vim.api.nvim_create_autocmd("WinClosed", {
      pattern = tostring(v.win),
      once = true,
      callback = function()
        if viewers[src_buf] and viewers[src_buf].win == v.win then
          viewers[src_buf].win = nil
          X.close(src_buf)
        end
      end,
    })
  end

  show_loading(v)
  X.render(file, function(png)
    local cur = viewers[src_buf]
    if not cur or cur ~= v or not viewer_valid(v) or not vim.api.nvim_buf_is_valid(v.buf) then
      return
    end
    v.spinner = nil
    v.png = png
    vim.api.nvim_win_set_config(v.win, win_geometry(png, v.zoom))
    vim.bo[v.buf].modifiable = true
    vim.api.nvim_buf_set_lines(v.buf, 0, -1, false, {})
    Snacks.image.buf.attach(v.buf, { src = png })
  end, force)
end

function X.toggle(src_buf)
  src_buf = src_buf or vim.api.nvim_get_current_buf()
  if viewer_valid(viewers[src_buf]) then
    X.close(src_buf)
  else
    X.show_image(src_buf)
  end
end

local function setup_buffer(buf)
  local map = function(lhs, fn, desc)
    vim.keymap.set("n", lhs, fn, { buffer = buf, desc = desc })
  end
  map("<leader>ix", function() X.toggle(buf) end, "Excalidraw: abrir/cerrar visor")
  map("<leader>ir", function() X.show_image(buf, true) end, "Excalidraw: re-renderizar")
  vim.api.nvim_buf_create_user_command(buf, "Excalidraw", function(o)
    local a = o.args ~= "" and o.args or "toggle"
    if a == "image" then X.show_image(buf)
    elseif a == "source" then X.close(buf)
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
          -- visor automático al abrir
          vim.defer_fn(function()
            if vim.api.nvim_buf_is_valid(ev.buf) and vim.api.nvim_get_current_buf() == ev.buf then
              X.show_image(ev.buf)
            end
          end, 50)
        end,
      })
      -- al guardar la fuente con el visor abierto, re-renderizar
      vim.api.nvim_create_autocmd("BufWritePost", {
        group = group,
        pattern = { "*.excalidraw", "*.excalidraw.md" },
        callback = function(ev)
          if viewer_valid(viewers[ev.buf]) then
            X.show_image(ev.buf, true)
          end
        end,
      })
      vim.api.nvim_create_autocmd("BufWipeout", {
        group = group,
        pattern = { "*.excalidraw", "*.excalidraw.md" },
        callback = function(ev)
          X.close(ev.buf)
        end,
      })
    end,
  },
}
