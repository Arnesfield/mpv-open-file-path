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
---@return { valid_key: boolean, value: string|nil }
local function resolve_kv_pair(key, value, kv_table)
  ---@type string|nil
  local result
  local valid_key = true

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
  else
    valid_key = false
  end

  return { valid_key = valid_key, value = result }
end

---@param str string
---@param modifiers table
---@return string
local function apply_modifiers(str, modifiers)
  local result = str

  for _, value in ipairs(modifiers) do
    -- include other modifiers here
    if value == 'path' then
      result = mp.command_native({ 'expand-path', result })
    else
      mp.msg.warn(string.format("Unrecognized modifier: '%s'", value))
    end
  end

  return result;
end

local var_table = build_kv_table(options.vars, options.vars_delimiter)

---@param arg string
---@param command_mode? boolean
local function parse_arg(arg, command_mode)
  if command_mode then
    local match = arg:match('^:(.*)')
    if match == nil then
      return arg
    end

    -- remove colon
    arg = match
  end

  local use_raw = false

  ---@type string|nil
  local result
  ---@type string|nil, string|nil
  local key, value = arg:match('^@([^/]+)/(.*)')

  if key ~= nil and value ~= nil then
    ---@type string[]
    local modifiers = {}

    -- split by dot to get modifiers
    for part in string.gmatch(key, '([^.]+)') do
      -- first match should be the value
      if result == nil then
        local resolved = resolve_kv_pair(part, value, var_table)

        if resolved.value ~= nil then
          result = resolved.value
        else
          -- if not a valid key, then use the raw value as is
          use_raw = not resolved.valid_key

          -- stop loop if no value since we don't need to apply the modifiers
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
    result = resolve_kv_pair('key', arg, var_table).value
  else
    use_raw = true
  end

  if use_raw then
    -- in command mode, placeholders with the colon prefix should have a value
    if command_mode then
      result = nil
    else
      result = arg
    end
  end

  return result
end

---@param args string[]
local function run_async(args)
  mp.msg.info('Running:', table.concat(args, ' '))

  mp.command_native_async({
    name = 'subprocess',
    capture_stderr = false,
    capture_stdout = false,
    playback_only = false,
    args = args
  })
end


---@param arg string|nil
local function run(arg)
  -- arg
  -- @cmd
  -- @key[.path.modifier]/{placeholder-key}
  -- @raw[.path.modifier]/{value}
  -- @property[.path.modifier]/{property-key}
  -- @computed[.path.modifier]/{computed-key}

  -- return early
  if not options.command then
    mp.msg.error("Option 'command' is required.")
    return
  elseif arg == nil then
    mp.msg.error('Argument to run is required.')
    return
  end

  local parsed = parse_arg(arg)

  -- return early
  if parsed == nil then
    mp.msg.error(string.format("Unable to parse: '%s'", arg))
    return
  end

  run_async({ options.command, parsed })
end

---@vararg string
local function run_cmd(...)
  ---@type string[]
  local cmd_args = {}

  for i, arg in ipairs({ ... }) do
    local parsed = parse_arg(arg, true)

    -- return early
    if parsed == nil then
      mp.msg.error(string.format("Unable to parse args[%d]: '%s'", i, arg))
      return
    end

    table.insert(cmd_args, parsed)
  end

  if #cmd_args > 0 then
    run_async(cmd_args)
  else
    mp.msg.warn('No arguments to run.')
  end
end

---@vararg string
local function run_parse(...)
  local args = { ... }
  ---@type string[]
  local result = {}

  for _, value in ipairs(args) do
    local parsed = parse_arg(value)
    parsed = parsed ~= nil and parsed or 'nil'
    table.insert(result, parsed)
  end

  mp.msg.info(table.concat(result, ', '))
end

mp.register_script_message('run', run)
mp.register_script_message('run-cmd', run_cmd)
mp.register_script_message('run-parse', run_parse)
