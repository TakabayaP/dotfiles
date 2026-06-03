local _term_buf = nil

local function toggle_terminal()
  if _term_buf and vim.api.nvim_buf_is_valid(_term_buf) then
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      if vim.api.nvim_win_get_buf(win) == _term_buf then
        local wins = vim.tbl_filter(function(w)
          return vim.api.nvim_win_get_config(w).relative == ""
        end, vim.api.nvim_tabpage_list_wins(0))
        if #wins <= 1 then
          vim.cmd("enew")
        end
        vim.api.nvim_win_hide(win)
        return
      end
    end
    vim.cmd("botright 15split")
    vim.api.nvim_set_current_buf(_term_buf)
    vim.cmd("startinsert")
  else
    vim.cmd("botright 15split | terminal")
    _term_buf = vim.api.nvim_get_current_buf()
    vim.cmd("startinsert")
  end
end

vim.keymap.set({ "n", "t", "i" }, "<F19>", toggle_terminal, { desc = "ターミナル切替 (Cmd+J)" })
