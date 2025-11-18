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
  path_map = 'screenshot-directory=@property/screenshot-directory:parent-directory=@computed/parent-directory',
  path_map_delimiter = ':',
}

mp.options.read_options(options, "open-file-path")

local computed = {
  -- Open the parent directory of the current file.
  parent_directory = '@computed/parent-directory'
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

-- key1=/path/to/open:key2=@property/property-key
local function build_path_map(path_map_str, delimiter)
  local path_map = {}

  if path_map_str then
    local pattern = get_split_pattern(delimiter)
    local property_prefix = '@property/'

    for part in string.gmatch(path_map_str, pattern) do
      local key, value = part:match("(.*)=(.*)")
      local path

      -- check for computed properties
      if value == computed.parent_directory then
        local file_path = mp.get_property('path')
        if file_path ~= nil then
          -- assign the directory to path
          path = mp.utils.split_path(file_path)
        end
      elseif string_starts_with(value, property_prefix) then
        -- get property if value starts with the property prefix
        local property = string.sub(value, string.len(property_prefix) + 1)
        path = mp.get_property(property)
      else
        path = value
      end

      if path ~= nil then
        path_map[key] = path
      end
    end
  end

  return path_map
end

local parsed_args = parse_args(options.args, options.args_delimiter)

-- don't build path map if computed value is needed
local cached_path_map
if not string.find(options.path_map, '@computed/') then
  cached_path_map = build_path_map(options.path_map, options.path_map_delimiter)
end

local function open_file_path(key)
  local path_map = cached_path_map or build_path_map(options.path_map, options.path_map_delimiter)
  local path = path_map[key]

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
  elseif path == nil then
    mp.msg.warn("No valid path associated with key: '" .. key .. "'")
  else
    mp.msg.warn('No valid path to open.')
  end
end

mp.register_script_message('open-file-path', open_file_path)
