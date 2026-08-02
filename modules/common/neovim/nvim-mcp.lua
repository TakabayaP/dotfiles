local M = {}

local started = false
local transient_names = {
  COMMIT_EDITMSG = true,
  MERGE_MSG = true,
  SQUASH_MSG = true,
  TAG_EDITMSG = true,
  ["git-rebase-todo"] = true,
}

local function socket_dir()
  if vim.fn.has("win32") == 1 then
    return vim.env.TEMP
  end
  -- macOS TMPDIR paths are long enough to exceed the Unix socket path limit
  -- once the repository path is embedded in the nvim-mcp socket name.
  if vim.fn.has("mac") == 1 then
    return "/tmp"
  end
  if vim.env.XDG_RUNTIME_DIR and vim.env.XDG_RUNTIME_DIR ~= "" then
    return vim.env.XDG_RUNTIME_DIR:gsub("/+$", "")
  end
  if vim.env.TMPDIR and vim.env.TMPDIR ~= "" then
    return vim.env.TMPDIR:gsub("/+$", "")
  end
  return "/tmp"
end

local function repository_root(path)
  local directory = path
  if directory == "" then
    directory = vim.fn.getcwd()
  elseif vim.fn.isdirectory(directory) ~= 1 then
    directory = vim.fs.dirname(directory)
  end

  local result = vim.system(
    { "git", "-C", directory, "rev-parse", "--show-toplevel" },
    { text = true }
  ):wait()
  if result.code ~= 0 then
    return nil
  end

  local root = vim.trim(result.stdout or "")
  return root ~= "" and root or nil
end

local function git_root(buf)
  if not vim.api.nvim_buf_is_valid(buf) or vim.bo[buf].buftype ~= "" then
    return nil
  end

  local path = vim.api.nvim_buf_get_name(buf)
  if path ~= "" then
    if transient_names[vim.fs.basename(path)] then
      return nil
    end
    return repository_root(path)
  end

  return repository_root(vim.fn.getcwd())
end

local function start(buf)
  if started then
    return
  end

  local root = git_root(buf)
  if not root then
    return
  end

  local escaped_root = vim.trim(root):gsub("/", "%%")
  local pipe = ("%s/nvim-mcp.%s.%d.sock"):format(socket_dir(), escaped_root, vim.fn.getpid())
  local ok, err = pcall(require("nvim-mcp").setup, { pipe = pipe })
  if not ok then
    vim.notify("Failed to start nvim-mcp: " .. tostring(err), vim.log.levels.ERROR)
    return
  end
  if not vim.tbl_contains(vim.fn.serverlist(), pipe) then
    vim.notify("Failed to start nvim-mcp server: " .. pipe, vim.log.levels.ERROR)
    return
  end

  started = true
  vim.g.nvim_mcp_socket = pipe
end

function M.setup()
  local group = vim.api.nvim_create_augroup("NvimMcpGitRepository", { clear = true })

  vim.api.nvim_create_autocmd("BufEnter", {
    group = group,
    callback = function(ev)
      start(ev.buf)
    end,
  })

  vim.schedule(function()
    start(vim.api.nvim_get_current_buf())
  end)
end

return M
