_G._file_cache = nil

local refresh_timer = nil
local fs_watchers = {}
local is_mac = vim.uv.os_uname().sysname == "Darwin"

local excluded_dirs = { ".git", "node_modules", ".next", "dist", "build", ".cache" }

local function is_excluded(name)
  for _, ex in ipairs(excluded_dirs) do
    if name == ex then
      return true
    end
  end
  return false
end

local function refresh_file_cache()
  vim.fn.jobstart({ "fd", "--type", "f", "--hidden", "--exclude", ".git" }, {
    stdout_buffered = true,
    on_stdout = function(_, data)
      _G._file_cache = vim.tbl_filter(function(line)
        return line ~= ""
      end, data)
    end,
  })
end

local function debounced_refresh()
  if refresh_timer then
    refresh_timer:stop()
  else
    refresh_timer = vim.uv.new_timer()
  end
  refresh_timer:start(200, 0, vim.schedule_wrap(refresh_file_cache))
end

local function stop_all_watchers()
  for _, w in ipairs(fs_watchers) do
    if w:is_active() then
      w:stop()
    end
    w:close()
  end
  fs_watchers = {}
end

local function on_fs_change(err, filename)
  if err then
    return
  end
  if filename and is_excluded(filename) then
    return
  end
  debounced_refresh()
end

local function watch_dir(dir)
  local w = vim.uv.new_fs_event()
  if not w then
    return
  end
  local ok = w:start(dir, {}, vim.schedule_wrap(on_fs_change))
  if ok == 0 then
    table.insert(fs_watchers, w)
  else
    w:close()
  end
end

local function start_fs_watch()
  stop_all_watchers()
  local cwd = vim.fn.getcwd()

  if is_mac then
    local w = vim.uv.new_fs_event()
    if w then
      local ok = w:start(cwd, { recursive = true }, vim.schedule_wrap(on_fs_change))
      if ok == 0 then
        table.insert(fs_watchers, w)
      else
        w:close()
      end
    end
  else
    watch_dir(cwd)
    vim.fn.jobstart({ "fd", "--type", "d", "--hidden", "--exclude", ".git", "--exclude", "node_modules", "--exclude", ".next", "--exclude", "dist", "--exclude", "build", "--exclude", ".cache" }, {
      cwd = cwd,
      stdout_buffered = true,
      on_stdout = function(_, data)
        vim.schedule(function()
          for _, dir in ipairs(data) do
            if dir ~= "" then
              local full = cwd .. "/" .. dir
              watch_dir(full)
            end
          end
        end)
      end,
    })
  end
end

vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    refresh_file_cache()
    start_fs_watch()
  end,
})

vim.api.nvim_create_autocmd("DirChanged", {
  callback = function()
    refresh_file_cache()
    start_fs_watch()
  end,
})

vim.api.nvim_create_autocmd("BufAdd", {
  callback = function(ev)
    local path = vim.api.nvim_buf_get_name(ev.buf)
    if path ~= "" and _G._file_cache and not vim.tbl_contains(_G._file_cache, path) then
      debounced_refresh()
    end
  end,
})

local function cached_find_files()
  if _G._file_cache then
    require("telescope.pickers")
      .new({}, {
        prompt_title = "Find Files",
        finder = require("telescope.finders").new_table({ results = _G._file_cache }),
        sorter = require("telescope.config").values.file_sorter({}),
        previewer = require("telescope.config").values.file_previewer({}),
      })
      :find()
  else
    require("telescope.builtin").find_files()
  end
end

vim.keymap.set("n", "<leader>ff", cached_find_files, { desc = "Find Files" })
vim.keymap.set("n", "<F13>", cached_find_files, { desc = "Find Files (Cmd+P)" })
