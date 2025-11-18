-- open-file-path.lua
--
-- Open file path in mpv.
--
-- https://github.com/Arnesfield/mpv-open-file-path

mp.msg = require('mp.msg')
mp.options = require('mp.options')
mp.utils = require('mp.utils')

local options = {
  command = 'xdg-open',
  args = '',
  args_delimiter = ',',
}

mp.options.read_options(options, "open-file-path")

local computed = {
  -- Open the parent directory of the current file.
  parent_directory = '@computed/parent-directory'
}

local prefix = {
  property = '@property/',
  computed = '@computed/'
}

local function string_starts_with(string, start)
  return string.sub(string, 1, string.len(start)) == start
end

local function get_split_pattern(delimiter)
  return '([^' .. delimiter .. ']+)'
end

local function table_append(source_table, table)
  for i = 1, #table do
    source_table[#source_table + 1] = table[i]
  end
  return source_table
end

local function parse_args(args, delimiter)
  local parsed_args = {}
  local pattern = get_split_pattern(delimiter)

  if args then
    for arg in string.gmatch(args, pattern) do
      table.insert(parsed_args, arg)
    end
  end

  return parsed_args
end

local function get_path(value)
  local path

  -- get property if value starts with the property prefix
  if string_starts_with(value, prefix.property) then
    local property = string.sub(value, string.len(prefix.property) + 1)
    path = mp.get_property(property)
  elseif string_starts_with(value, prefix.computed) then
    -- check for computed properties
    if value == computed.parent_directory then
      local file_path = mp.get_property('path')
      if file_path ~= nil then
        -- assign the directory to path
        path = mp.utils.split_path(file_path)
      end
    end
  else
    path = value
  end

  return path
end

local parsed_args = parse_args(options.args, options.args_delimiter)

local function open_file_path(flag)
  local path = get_path(flag)

  if path then
    local absolute_path = mp.command_native({ "expand-path", path })
    local args = { options.command }
    table_append(args, parsed_args)
    table.insert(args, absolute_path)

    mp.msg.info('Running:', table.concat(args, ' '))

    mp.command_native_async({
      name = 'subprocess',
      capture_stderr = false,
      capture_stdout = false,
      playback_only = false,
      args = args
    })
  else
    mp.msg.warn("Unable to open path: '" .. flag .. "'")
  end
end

mp.register_script_message('open-file-path', open_file_path)
