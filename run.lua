-- run.lua
--
-- Run commands in mpv via script-message.
--
-- https://github.com/Arnesfield/mpv-run

mp.msg = require('mp.msg')
mp.options = require('mp.options')
mp.utils = require('mp.utils')

local options = {
  command = 'xdg-open',
  vars = 'command=xdg-open',
  vars_delimiter = ',',
}

mp.options.read_options(options, 'run')

local computed = {
  -- Open the parent directory of the current file.
  parent_directory = 'parent-directory'
}

---@param kv_str string
---@param delimiter string
---@return table
local function build_kv_table(kv_str, delimiter)
  local result = {}

  if kv_str then
    local pattern = string.format('([^=%s]+)=([^%s]*)', delimiter, delimiter)
    for key, value in string.gmatch(kv_str, pattern) do
      result[key] = value
    end
  end

  return result
end

---@param key 'raw'|'key'|'property'|'computed'|string
---@param value string
---@param kv_table table
---@return string|nil
local function resolve_kv_pair(key, value, kv_table)
  local result

  if key == 'raw' then
    -- use value as is
    result = value
  elseif key == 'key' then
    -- use the value from the kv table
    result = kv_table[value]
  elseif key == 'property' then
    -- get value by property
    result = mp.get_property(value)
  elseif key == 'computed' then
    -- check for computed properties
    if value == computed.parent_directory then
      local file_path = mp.get_property('path')
      if file_path ~= nil then
        -- assign the directory to path
        result = mp.utils.split_path(file_path)
      end
    end
  end

  return result
end

---@param str string
---@param modifiers table
---@return string
local function apply_modifiers(str, modifiers)
  local result = str

  for _, value in ipairs(modifiers) do
    -- include other modifiers here
    if value == 'path' then
      result = mp.command_native({ "expand-path", result })
    end
  end

  return result;
end

local var_table = build_kv_table(options.vars, options.vars_delimiter)

---@param arg string
---@param command_mode? boolean
local function parse_arg(arg, command_mode)
  ---@type string|nil
  local result
  local pattern = string.format('%s@([^/]+)/(.*)', command_mode and ':' or '')
  ---@type string|nil, string|nil
  local key, value = arg:match(pattern)

  if key ~= nil and value ~= nil then
    local modifiers = {}

    -- split by dot to get modifiers
    for part in string.gmatch(key, '([^.]+)') do
      -- first match should be the value
      if result == nil then
        result = resolve_kv_pair(part, value, var_table)

        -- stop loop if no value since we don't need to apply the modifiers
        if result == nil then
          break
        end
      else
        table.insert(modifiers, part)
      end
    end

    -- apply value modifiers
    if result ~= nil then
      result = apply_modifiers(result, modifiers)
    end
  elseif command_mode then
    -- use raw value if no match
    result = arg:match(':(.*)')
    result = result ~= nil and resolve_kv_pair('key', result, var_table) or arg
  else
    -- use raw value
    result = arg
  end

  return result
end

---@vararg string
local function run(...)
  -- arg
  -- @cmd
  -- @key[.path.modifier]/{placeholder-key}
  -- @raw[.path.modifier]/{value}
  -- @property[.path.modifier]/{property-key}
  -- @computed[.path.modifier]/{computed-key}

  local args = { ... }
  local arg1 = args[1]
  ---@type string[]
  local cmd_args = {}

  if arg1 ~= nil and arg1 ~= '@cmd' then
    -- return early
    if not options.command then
      mp.msg.error("Option 'command' is required.")
      return
    end

    local parsed = parse_arg(arg1)

    -- return early
    if parsed == nil then
      mp.msg.error(string.format("Unable to parse: '%s'", arg1))
      return
    end

    table.insert(cmd_args, options.command)
    table.insert(cmd_args, parsed)
  else
    -- command mode
    for i = 2, #args do
      local arg = args[i]
      local parsed = parse_arg(arg, true)

      -- return early
      if parsed == nil then
        mp.msg.error(string.format("Unable to parse args[%d]: '%s'", i, arg))
        return
      end

      table.insert(cmd_args, parsed)
    end
  end

  if #cmd_args > 0 then
    mp.msg.info('Running:', table.concat(cmd_args, ' '))

    mp.command_native_async({
      name = 'subprocess',
      capture_stderr = false,
      capture_stdout = false,
      playback_only = false,
      args = cmd_args
    })
  else
    local message = arg1 ~= nil
        and string.format("Unrecognized argument: '%s'", arg1)
        or 'No arguments.'
    mp.msg.warn(message)
  end
end

mp.register_script_message('run', run)
