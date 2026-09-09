-- Close the in-Neovim LazyGit float, then show the file in a real window.
-- The stock nvim-remote preset opens a tab behind the float and leaves focus there.

local M = {}

local function close_lazygit_window()
  local win = vim.api.nvim_get_current_win()
  local cfg = vim.api.nvim_win_get_config(win)
  local is_float = cfg.relative ~= nil and cfg.relative ~= ""
  local buf = vim.api.nvim_win_get_buf(win)
  local is_terminal = vim.bo[buf].buftype == "terminal"
  if (is_float or is_terminal) and #vim.api.nvim_list_wins() > 1 then
    pcall(vim.api.nvim_win_close, win, true)
  end
end

local function abs_path(path)
  return vim.fn.fnamemodify(path, ":p")
end

function M.edit(filename, line)
  if filename == nil or filename == "" then
    return
  end

  close_lazygit_window()

  vim.schedule(function()
    vim.cmd.stopinsert()
    local target = abs_path(filename)
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      local buf = vim.api.nvim_win_get_buf(win)
      if abs_path(vim.api.nvim_buf_get_name(buf)) == target then
        vim.api.nvim_set_current_win(win)
        local n = tonumber(line)
        if n and n > 0 then
          pcall(vim.api.nvim_win_set_cursor, win, { n, 0 })
        end
        return
      end
    end

    vim.cmd.edit(vim.fn.fnameescape(filename))
    local n = tonumber(line)
    if n and n > 0 then
      pcall(vim.api.nvim_win_set_cursor, 0, { n, 0 })
    end
  end)
end

return M
