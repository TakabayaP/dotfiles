_G._file_cache = nil

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

vim.api.nvim_create_autocmd("VimEnter", { callback = refresh_file_cache })
vim.api.nvim_create_autocmd("DirChanged", { callback = refresh_file_cache })
vim.api.nvim_create_autocmd("BufWritePost", {
  callback = function(ev)
    local path = ev.file
    if _G._file_cache and not vim.tbl_contains(_G._file_cache, path) then
      refresh_file_cache()
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
