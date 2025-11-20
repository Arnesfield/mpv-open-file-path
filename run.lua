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
  -- Get the parent directory of the current file.
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

---@param key 'raw'|'var'|'property'|'computed'|string
---@param value string
---@param kv_table table
---@return { value: string|nil, valid_key: boolean }
local function resolve_kv_pair(key, value, kv_table)
  ---@type string|nil
  local result
  local valid_key = true

  if key == 'raw' then
    -- use value as is
    result = value
  elseif key == 'var' then
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

  return { value = result, valid_key = valid_key }
end

---@param value string
---@param modifiers table
---@return { value: string, unrecognized: string[] }
local function apply_modifiers(value, modifiers)
  ---@type string[]
  local unrecognized = {}

  for _, modifier in ipairs(modifiers) do
    -- include other modifiers here
    if modifier == 'path' then
      value = mp.command_native({ 'expand-path', value })
    else
      table.insert(unrecognized, modifier)
    end
  end

  return { value = value, unrecognized = unrecognized }
end

local var_table = build_kv_table(options.vars, options.vars_delimiter)

---@param arg string
local function parse_arg(arg)
  ---@type string|nil
  local result
  ---@type string|nil, string|nil
  local key, value = arg:match('^@([^/]+)/(.+)')

  if key ~= nil and value ~= nil then
    ---@type string[]
    local modifiers = {}

    -- split by dot to get modifiers
    for modifier in string.gmatch(key, '([^.]+)') do
      -- first match is the main key and not a modifier
      if result == nil then
        local resolved = resolve_kv_pair(modifier, value, var_table)

        if resolved.value ~= nil then
          result = resolved.value
        else
          -- if not a valid key, then use the raw value as is
          if not resolved.valid_key then
            result = arg
          end

          -- stop loop if no value since we don't need to apply the modifiers
          break
        end
      else
        table.insert(modifiers, modifier)
      end
    end

    -- apply value modifiers
    if result ~= nil then
      local apply_result = apply_modifiers(result, modifiers)
      local unrecognized = apply_result.unrecognized
      result = apply_result.value

      if #unrecognized > 0 then
        ---@type string[]
        local wrapped_modifiers = {}
        for _, modifier in ipairs(unrecognized) do
          table.insert(wrapped_modifiers, string.format("'%s'", modifier))
        end

        local suffix = #unrecognized == 1 and '' or 's'
        local list = table.concat(wrapped_modifiers, ', ')
        mp.msg.warn(string.format("Argument '%s' has unrecognized modifier%s: %s", arg, suffix, list))
      end
    end
  else
    result = arg
  end

  return result
end

---@param args string[]
local function run_command_async(args)
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
  -- return early
  if not options.command then
    mp.msg.error("Option 'command' is required.")
    return
  elseif arg == nil then
    mp.msg.error('No argument to run.')
    return
  end

  local parsed = parse_arg(arg)

  -- return early
  if parsed == nil then
    mp.msg.error(string.format("Argument '%s' was parsed as 'nil'.", arg))
    return
  end

  run_command_async({ options.command, parsed })
end

---@vararg string
local function run_cmd(...)
  ---@type string[]
  local cmd_args = {}

  for i, arg in ipairs({ ... }) do
    local parsed = parse_arg(arg)

    -- return early
    if parsed == nil then
      mp.msg.error(string.format("Argument '%s' at index %d was parsed as 'nil'.", arg, i))
      return
    end

    table.insert(cmd_args, parsed)
  end

  if #cmd_args > 0 then
    run_command_async(cmd_args)
  else
    mp.msg.warn('No arguments to run.')
  end
end

---@vararg string
local function run_parse(...)
  ---@type string[]
  local result = {}

  for _, value in ipairs({ ... }) do
    local parsed = parse_arg(value)
    parsed = parsed ~= nil and parsed or 'nil'
    table.insert(result, parsed)
  end

  if #result > 0 then
    mp.msg.info(table.concat(result, ', '))
  else
    mp.msg.warn('No arguments to parse.')
  end
end

mp.register_script_message('run', run)
mp.register_script_message('run-cmd', run_cmd)
mp.register_script_message('run-parse', run_parse)
