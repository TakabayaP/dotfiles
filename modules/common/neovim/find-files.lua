local M = {}

_G._file_cache = nil

local refresh_timer = nil
local refresh_job = nil
local directory_scan_job = nil
local fs_watchers = {}
local active_cwd = nil
local generation = 0
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

local function stop_job(job)
  if job and job > 0 then
    vim.fn.jobstop(job)
  end
end

local function stop_all_watchers()
  for _, watcher in ipairs(fs_watchers) do
    if not watcher:is_closing() then
      if watcher:is_active() then
        watcher:stop()
      end
      watcher:close()
    end
  end
  fs_watchers = {}
end

local function stop_tracking()
  generation = generation + 1
  active_cwd = nil
  _G._file_cache = nil

  if refresh_timer and refresh_timer:is_active() then
    refresh_timer:stop()
  end

  stop_job(refresh_job)
  stop_job(directory_scan_job)
  refresh_job = nil
  directory_scan_job = nil
  stop_all_watchers()
end

local function refresh_file_cache()
  if not active_cwd then
    return
  end

  stop_job(refresh_job)

  local cwd = active_cwd
  local scan_generation = generation
  local job
  job = vim.fn.jobstart({ "fd", "--type", "f", "--hidden", "--exclude", ".git" }, {
    cwd = cwd,
    stdout_buffered = true,
    on_stdout = function(_, data)
      if active_cwd ~= cwd or generation ~= scan_generation then
        return
      end
      _G._file_cache = vim.tbl_filter(function(line)
        return line ~= ""
      end, data)
    end,
    on_exit = function()
      if refresh_job == job then
        refresh_job = nil
      end
    end,
  })
  refresh_job = job > 0 and job or nil
end

local function debounced_refresh()
  if not active_cwd then
    return
  end

  if refresh_timer then
    refresh_timer:stop()
  else
    refresh_timer = vim.uv.new_timer()
  end
  refresh_timer:start(200, 0, vim.schedule_wrap(refresh_file_cache))
end

local function on_fs_change(err, filename)
  if err or not active_cwd then
    return
  end
  if filename and is_excluded(filename) then
    return
  end
  debounced_refresh()
end

local function watch_dir(dir)
  local watcher = vim.uv.new_fs_event()
  if not watcher then
    return
  end
  local ok = watcher:start(dir, {}, vim.schedule_wrap(on_fs_change))
  if ok == 0 then
    table.insert(fs_watchers, watcher)
  else
    watcher:close()
  end
end

local function start_fs_watch()
  if not active_cwd then
    return
  end

  stop_all_watchers()
  stop_job(directory_scan_job)
  directory_scan_job = nil

  local cwd = active_cwd
  local scan_generation = generation

  if is_mac then
    local watcher = vim.uv.new_fs_event()
    if watcher then
      local ok = watcher:start(cwd, { recursive = true }, vim.schedule_wrap(on_fs_change))
      if ok == 0 then
        table.insert(fs_watchers, watcher)
      else
        watcher:close()
      end
    end
  else
    watch_dir(cwd)
    local job
    job = vim.fn.jobstart({
      "fd",
      "--type",
      "d",
      "--hidden",
      "--exclude",
      ".git",
      "--exclude",
      "node_modules",
      "--exclude",
      ".next",
      "--exclude",
      "dist",
      "--exclude",
      "build",
      "--exclude",
      ".cache",
    }, {
      cwd = cwd,
      stdout_buffered = true,
      on_stdout = function(_, data)
        if active_cwd ~= cwd or generation ~= scan_generation then
          return
        end
        vim.schedule(function()
          if active_cwd ~= cwd or generation ~= scan_generation then
            return
          end
          for _, dir in ipairs(data) do
            if dir ~= "" then
              watch_dir(cwd .. "/" .. dir)
            end
          end
        end)
      end,
      on_exit = function()
        if directory_scan_job == job then
          directory_scan_job = nil
        end
      end,
    })
    directory_scan_job = job > 0 and job or nil
  end
end

local function start_tracking_current_directory()
  stop_tracking()

  local cwd = vim.fs.normalize(vim.fn.getcwd())
  local result = vim.system(
    { "git", "-C", cwd, "rev-parse", "--show-toplevel" },
    { text = true }
  ):wait()
  if result.code ~= 0 or vim.trim(result.stdout or "") == "" then
    return
  end

  active_cwd = cwd
  refresh_file_cache()
  start_fs_watch()
end

local function warn_outside_git_repo()
  vim.notify("File search is disabled outside a Git repository", vim.log.levels.WARN)
end

local function cached_find_files()
  if not active_cwd then
    warn_outside_git_repo()
    return
  end

  if _G._file_cache then
    require("telescope.pickers")
      .new({ cwd = active_cwd }, {
        prompt_title = "Find Files",
        finder = require("telescope.finders").new_table({ results = _G._file_cache }),
        sorter = require("telescope.config").values.file_sorter({}),
        previewer = require("telescope.config").values.file_previewer({}),
      })
      :find()
  else
    require("telescope.builtin").find_files({ cwd = active_cwd })
  end
end

function M.live_grep()
  if not active_cwd then
    warn_outside_git_repo()
    return
  end
  require("telescope.builtin").live_grep({ cwd = active_cwd })
end

function M.cache_root()
  return active_cwd
end

local group = vim.api.nvim_create_augroup("GitRepoFileCache", { clear = true })

vim.api.nvim_create_autocmd("VimEnter", {
  group = group,
  callback = start_tracking_current_directory,
})

vim.api.nvim_create_autocmd("DirChanged", {
  group = group,
  callback = start_tracking_current_directory,
})

vim.api.nvim_create_autocmd("BufAdd", {
  group = group,
  callback = function(ev)
    if not active_cwd or not _G._file_cache then
      return
    end

    local path = vim.fs.normalize(vim.api.nvim_buf_get_name(ev.buf))
    local prefix = active_cwd .. "/"
    if path ~= "" and vim.startswith(path, prefix) then
      local relative_path = path:sub(#prefix + 1)
      if not vim.tbl_contains(_G._file_cache, relative_path) then
        debounced_refresh()
      end
    end
  end,
})

vim.api.nvim_create_autocmd("VimLeavePre", {
  group = group,
  callback = function()
    stop_tracking()
    if refresh_timer and not refresh_timer:is_closing() then
      refresh_timer:close()
      refresh_timer = nil
    end
  end,
})

vim.keymap.set("n", "<leader>ff", cached_find_files, { desc = "Find Files" })
vim.keymap.set("n", "<F13>", cached_find_files, { desc = "Find Files (Cmd+P)" })

return M
