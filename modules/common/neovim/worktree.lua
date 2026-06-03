require("telescope").load_extension("git_worktree")

local hooks = require("git-worktree.hooks")
hooks.register(hooks.type.SWITCH, function(path, prev_path)
  vim.schedule(function()
    vim.cmd("%bdelete!")
    local ok, persistence = pcall(require, "persistence")
    if ok then
      persistence.load()
    end
    vim.cmd("doautoall FileType")
  end)
end)
hooks.register(hooks.type.DELETE, function(path)
  vim.schedule(function()
    if path then
      _G._wt_diff_cache[path] = nil
    end
    if _G._wt_update_cache then
      _G._wt_update_cache()
    end
  end)
end)

_G._wt_diff_cache = _G._wt_diff_cache or {}

local function wt_parse_list()
  local output = vim.fn.systemlist("git worktree list --porcelain")
  local worktrees = {}
  local w = {}
  for _, line in ipairs(output) do
    if line:match("^worktree ") then
      w = { path = line:match("^worktree (.+)") }
    elseif line:match("^branch ") then
      w.branch = line:match("^branch refs/heads/(.+)")
    elseif line == "" and w.path then
      table.insert(worktrees, w)
      w = {}
    end
  end
  if w.path then
    table.insert(worktrees, w)
  end
  return worktrees
end

local function wt_update_cache()
  local ok, worktrees = pcall(wt_parse_list)
  if not ok or #worktrees == 0 then
    _G._wt_diff_cache = {}
    return
  end
  local active_paths = {}
  for _, w in ipairs(worktrees) do
    active_paths[w.path] = true
  end
  for path in pairs(_G._wt_diff_cache) do
    if not active_paths[path] then
      _G._wt_diff_cache[path] = nil
    end
  end
  for _, w in ipairs(worktrees) do
    vim.fn.jobstart({ "git", "-C", w.path, "diff", "--numstat" }, {
      stdout_buffered = true,
      on_stdout = function(_, data)
        local add, del = 0, 0
        for _, line in ipairs(data) do
          local a, d = line:match("^(%d+)%s+(%d+)")
          if a then
            add = add + tonumber(a)
            del = del + tonumber(d)
          end
        end
        _G._wt_diff_cache[w.path] = { add = add, del = del }
      end,
    })
  end
end

_G._wt_update_cache = wt_update_cache

vim.keymap.set("n", "<leader>wt", function()
  wt_update_cache()
  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")

  local worktrees = wt_parse_list()

  local max_branch = 0
  for _, w in ipairs(worktrees) do
    local b = w.branch or "(detached)"
    if #b > max_branch then
      max_branch = #b
    end
  end

  pickers
    .new({}, {
      prompt_title = "Git Worktrees",
      finder = finders.new_table({
        results = worktrees,
        entry_maker = function(entry)
          local branch = entry.branch or "(detached)"
          local cache = _G._wt_diff_cache[entry.path] or { add = 0, del = 0 }
          local add_str = cache.add > 0 and string.format("+%d", cache.add) or ""
          local del_str = cache.del > 0 and string.format("-%d", cache.del) or ""

          local pad = string.rep(" ", max_branch - #branch)
          local diff_part = string.format("%6s %6s", add_str, del_str)
          local line = branch .. pad .. "  " .. diff_part

          local highlights = {}
          local diff_start = max_branch + 2
          if add_str ~= "" then
            local add_offset = diff_start + (6 - #add_str)
            table.insert(highlights, { { add_offset, add_offset + #add_str }, "GitSignsAdd" })
          end
          if del_str ~= "" then
            local del_offset = diff_start + 7 + (6 - #del_str)
            table.insert(highlights, { { del_offset, del_offset + #del_str }, "GitSignsDelete" })
          end

          return {
            value = entry,
            display = function()
              return line, highlights
            end,
            ordinal = branch,
          }
        end,
      }),
      sorter = conf.generic_sorter({}),
      attach_mappings = function(prompt_bufnr, map)
        actions.select_default:replace(function()
          local sel = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          if sel then
            require("persistence").save()
            require("git-worktree").switch_worktree(sel.value.path)
          end
        end)
        map("i", "<C-d>", function()
          local sel = action_state.get_selected_entry()
          if sel then
            actions.close(prompt_bufnr)
            require("git-worktree").delete_worktree(sel.value.path)
          end
        end)
        return true
      end,
    })
    :find()
end, { desc = "Git Worktree list/switch" })

vim.keymap.set("n", "<leader>wc", function()
  require("telescope").extensions.git_worktree.create_git_worktree()
end, { desc = "Git Worktree create" })
