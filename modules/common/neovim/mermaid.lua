local M = {}

local function is_git_markdown(buf)
  if not vim.api.nvim_buf_is_valid(buf) or vim.bo[buf].filetype ~= "markdown" then
    return false
  end

  local path = vim.api.nvim_buf_get_name(buf)
  if path == "" or vim.bo[buf].buftype ~= "" then
    return false
  end

  return vim.fs.root(path, ".git") ~= nil
end

local function attach(buf)
  if is_git_markdown(buf) then
    require("snacks.image.doc").attach(buf)
  end
end

local function with_rendered_image(callback)
  local source_buf = vim.api.nvim_get_current_buf()
  if not is_git_markdown(source_buf) then
    vim.notify("Image actions are available for Markdown files in Git repositories", vim.log.levels.WARN)
    return
  end

  Snacks.image.doc.at_cursor(function(src)
    if not src then
      vim.notify("No image or Mermaid diagram at cursor", vim.log.levels.WARN)
      return
    end

    local image = Snacks.image.image.new(src)
    local timer = assert(vim.uv.new_timer())
    local started = vim.uv.hrtime()

    timer:start(
      0,
      50,
      vim.schedule_wrap(function()
        if image:ready() then
          timer:stop()
          timer:close()
          callback(image.file)
        elseif image:failed() then
          timer:stop()
          timer:close()
          vim.notify("Image conversion failed", vim.log.levels.ERROR)
        elseif (vim.uv.hrtime() - started) / 1e9 > 15 then
          timer:stop()
          timer:close()
          vim.notify("Image conversion timed out", vim.log.levels.ERROR)
        end
      end)
    )
  end)
end

function M.preview_at_cursor()
  local source_buf = vim.api.nvim_get_current_buf()
  local source_win = vim.api.nvim_get_current_win()
  local source_view = vim.fn.winsaveview()
  if not is_git_markdown(source_buf) then
    vim.notify("Image preview is available for Markdown files in Git repositories", vim.log.levels.WARN)
    return
  end

  Snacks.image.doc.at_cursor(function(src)
    if not src then
      vim.notify("No image or Mermaid diagram at cursor", vim.log.levels.WARN)
      return
    end

    vim.schedule(function()
      if not vim.api.nvim_buf_is_valid(source_buf) or not vim.api.nvim_win_is_valid(source_win) then
        return
      end

      local win = source_win
      local buf = vim.api.nvim_create_buf(true, true)
      local source_name = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(source_buf), ":t")
      vim.api.nvim_buf_set_name(buf, ("image-preview://%d/%s"):format(buf, source_name))

      vim.bo[buf].buftype = "nofile"
      vim.bo[buf].bufhidden = "wipe"
      vim.bo[buf].swapfile = false
      vim.bo[buf].modifiable = true
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.fn["repeat"]({ "" }, 1000))
      vim.bo[buf].modifiable = false
      vim.bo[buf].filetype = "image"

      local window_options = {
        "wrap",
        "number",
        "relativenumber",
        "cursorline",
        "cursorcolumn",
        "signcolumn",
        "foldcolumn",
        "list",
        "spell",
        "statuscolumn",
        "fillchars",
      }
      local saved_window_options = {}
      for _, option in ipairs(window_options) do
        saved_window_options[option] = vim.wo[win][option]
      end

      vim.api.nvim_win_set_buf(win, buf)
      vim.wo[win].number = false
      vim.wo[win].relativenumber = false
      vim.wo[win].cursorline = false
      vim.wo[win].signcolumn = "no"
      vim.wo[win].foldcolumn = "0"
      vim.wo[win].statuscolumn = ""
      vim.wo[win].wrap = false
      vim.wo[win].fillchars = "eob: "

      local placement
      placement = Snacks.image.placement.new(buf, src, {
        inline = false,
        auto_resize = true,
        on_update_pre = function(current)
          if not vim.api.nvim_win_is_valid(win) then
            return
          end
          local state = current:state()
          local width = vim.api.nvim_win_get_width(win)
          local height = vim.api.nvim_win_get_height(win)
          current.opts.pos = {
            math.max(1, math.floor((height - state.loc.height) / 2) + 1),
            math.max(0, math.floor((width - state.loc.width) / 2)),
          }
        end,
      })

      -- Placement.state() fits within the window but intentionally does not
      -- upscale small images. Build the dedicated preview state explicitly so
      -- its width is always the current buffer width. The height calculation
      -- accounts for terminal cell aspect ratio, preserving the image shape.
      placement.state = function(current)
        local width = vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_width(win) or 1
        local dimensions = Snacks.image.util.dim(current.img.file)
        local terminal = Snacks.image.terminal.size()
        local height = math.max(
          1,
          math.floor(
            width * terminal.cell_width * dimensions.height / dimensions.width / terminal.cell_height + 0.5
          )
        )
        local pos = current.opts.pos or { 1, 0 }
        return {
          hidden = current.hidden or false,
          loc = {
            pos[1],
            pos[2],
            width = width,
            height = height,
          },
          wins = current:wins(),
        }
      end

      placement:update()

      local function restore_window()
        if not vim.api.nvim_win_is_valid(win) then
          return
        end
        for option, value in pairs(saved_window_options) do
          vim.wo[win][option] = value
        end
      end

      vim.keymap.set("n", "q", function()
        if vim.api.nvim_win_is_valid(win) and vim.api.nvim_buf_is_valid(source_buf) then
          vim.api.nvim_win_set_buf(win, source_buf)
          restore_window()
          vim.api.nvim_win_call(win, function()
            vim.fn.winrestview(source_view)
          end)
        elseif vim.api.nvim_buf_is_valid(buf) then
          vim.api.nvim_buf_delete(buf, { force = true })
        end
      end, { buffer = buf, desc = "Close image preview", silent = true })

      vim.api.nvim_create_autocmd("BufWipeout", {
        buffer = buf,
        once = true,
        callback = function()
          if placement then
            placement:close()
            placement = nil
          end
          restore_window()
        end,
      })
    end)
  end)
end

function M.copy_at_cursor()
  with_rendered_image(function(file)
    local command
    local options = { text = true }

    if vim.fn.has("mac") == 1 then
      local script = [[
on run argv
  set imageFile to POSIX file (item 1 of argv)
  set the clipboard to (read imageFile as «class PNGf»)
end run
]]
      command = { "osascript", "-e", script, file }
    elseif vim.env.WAYLAND_DISPLAY and vim.fn.executable("wl-copy") == 1 then
      local handle = assert(io.open(file, "rb"))
      options.stdin = handle:read("*a")
      handle:close()
      options.text = false
      command = { "wl-copy", "--type", "image/png" }
    elseif vim.fn.executable("xclip") == 1 then
      command = { "xclip", "-selection", "clipboard", "-t", "image/png", "-i", file }
    else
      vim.notify("No image clipboard command is available", vim.log.levels.ERROR)
      return
    end

    vim.system(command, options, function(result)
      vim.schedule(function()
        if result.code == 0 then
          vim.notify("Image copied to clipboard", vim.log.levels.INFO)
        else
          local message = vim.trim(result.stderr or "")
          vim.notify(message ~= "" and message or "Failed to copy image", vim.log.levels.ERROR)
        end
      end)
    end)
  end)
end

local group = vim.api.nvim_create_augroup("GitRepoMarkdownImages", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
  group = group,
  pattern = "markdown",
  callback = function(ev)
    vim.schedule(function()
      attach(ev.buf)
    end)
  end,
})

-- The initial file's FileType event can run before this module is loaded.
vim.schedule(function()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    attach(buf)
  end
end)

return M
