-- main module file
local uv = vim.loop

local dotenv = {}

dotenv.config = {
  enable_on_load = false,
}

local function read_file(path)
  local fd = assert(uv.fs_open(path, "r", 438))
  local stat = assert(uv.fs_fstat(fd))
  local data = assert(uv.fs_read(fd, stat.size, 0))
  assert(uv.fs_close(fd))
  return data
end

dotenv.setup = function(args)
  dotenv.config = vim.tbl_extend("force", dotenv.config, args or {})

  vim.api.nvim_create_user_command("Dotenv", dotenv.load, { nargs = 0 })

  if dotenv.config.enable_on_load then
    vim.api.nvim_create_autocmd("BufReadPost", { pattern = "*", callback = dotenv.load })
  end
end

dotenv.load = function()
  local path = vim.loop.cwd() .. "/.env"

  -- read file
  local ok, data = pcall(read_file, path)
  if not ok then
    vim.notify(".env file not found", vim.log.levels.ERROR)
    return
  end

  -- parse data
  local values = vim.split(data, "\n")
  for _, val in pairs(values) do
    local splitted = vim.split(val, "=")
    if #splitted == 2 then
      vim.env[splitted[1]] = vim.trim(splitted[2])
    end
  end

  vim.notify(".env file loaded")
end

return dotenv
