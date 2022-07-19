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

local function load()
  local path = vim.loop.cwd() .. "/.env"

  local ok, data = pcall(read_file, path)
  if not ok then
    vim.notify(".env file not found", vim.log.levels.ERROR)
    return
  end

  parse_data(data)
end

dotenv.setup = function(args)
  dotenv.config = vim.tbl_extend("force", dotenv.config, args or {})

  vim.api.nvim_create_user_command("Dotenv", dotenv.load, { nargs = 0 })
  vim.api.nvim_create_user_command("DotenvGet", function(opts)
    dotenv.get(opts.fargs)
  end, { nargs = 1 })

  if dotenv.config.enable_on_load then
    vim.api.nvim_create_autocmd("BufReadPost", { pattern = "*", callback = dotenv.load })
  end
end

dotenv.get = function(arg)
  if #debug then
    load()
  end
  local var = string.upper(arg[1])
  if vim.env[var] == nil then
    vim.notify(arg .. ": not found", vim.log.levels.ERROR)
    return
  end
  print(vim.env[var])
end

dotenv.load = function()
  load()
  vim.notify(".env file loaded")
end

return dotenv
