---@diagnostic disable: missing-parameter
-- main module file
local uv = vim.loop

local dotenv = {}

dotenv.config = {
  enable_on_load = false,
  verbose = false,
}

local function notify(msg, level)
  if not dotenv.config.verbose then
    return
  end

  if level == nil then
    level = "INFO"
  end

  vim.notify(msg, vim.log.levels[level])
end

local function read_file(path)
  local fd = assert(uv.fs_open(path, "r", 438))
  local stat = assert(uv.fs_fstat(fd))
  local data = assert(uv.fs_read(fd, stat.size, 0))
  assert(uv.fs_close(fd))
  return data
end

local function parse_data(data)
  local values = vim.split(data, "\n")
  local out = {}
  for _, pair in pairs(values) do
    pair = vim.trim(pair)
    if not vim.startswith(pair, "#") and pair ~= "" then
      local splitted = vim.split(pair, "=")
      if #splitted > 1 then
        local key = splitted[1]
        local v = {}
        for i = 2, #splitted, 1 do
          local k = vim.trim(splitted[i])
          if k ~= "" then
            table.insert(v, splitted[i])
          end
        end
        if #v > 0 then
          local value = table.concat(v, "=")
          value, _ = string.gsub(value, '"', "")
          vim.env[key] = value
          out[key] = value
        end
      end
    end
  end
  return out
end

local function get_env_file()
  local files = vim.fs.find(".env", { upward = true, type = "file" })
  if #files == 0 then
    return
  end
  return files[1]
end

local function load(file)
  if file == nil then
    file = get_env_file()
  end

  local ok, data = pcall(read_file, file)
  if not ok then
    notify(".env file not found", "ERROR")
    return
  end

  parse_data(data)
  notify(".env file loaded")
end

dotenv.setup = function(args)
  dotenv.config = vim.tbl_extend("force", dotenv.config, args or {})

  vim.api.nvim_create_user_command("Dotenv", function(opts)
    dotenv.command(opts)
  end, { nargs = "?", complete = "file" })
  vim.api.nvim_create_user_command("DotenvGet", function(opts)
    dotenv.get(opts.fargs)
  end, { nargs = 1 })

  if dotenv.config.enable_on_load then
    local group = vim.api.nvim_create_augroup("Dotenv", { clear = true })
    vim.api.nvim_create_autocmd("BufReadPost", { group = group, pattern = "*", callback = dotenv.autocmd })
  end
end

dotenv.get = function(arg)
  local var = string.upper(arg[1])
  if vim.env[var] == nil then
    print(var .. ": not found")
    return
  end
  print(vim.env[var])
end

dotenv.autocmd = function()
  load()
end

dotenv.command = function(opts)
  local args

  if opts ~= nil then
    if #opts.fargs > 0 then
      args = opts.fargs[1]
    end
  end

  load(args)
end

return dotenv
