# mpv-open-file-path

Open file path in [mpv](https://mpv.io/).

## Install

1. Download the following files to their appropriate directories under your mpv config (e.g., `~/.config/mpv`):

   [`open-file-path.lua`](open-file-path.lua) - Save to `scripts` directory.

   ```sh
   wget github.com/Arnesfield/mpv-open-file-path/raw/main/open-file-path.lua
   ```

   [`open-file-path.conf`](open-file-path.conf) - Save to `script-opts` directory. Includes defaults.

   ```sh
   wget github.com/Arnesfield/mpv-open-file-path/raw/main/open-file-path.conf
   ```

2. Use `script-message open-file-path <key>` in your `input.conf`. Example:

   ```conf
   ctrl+S script-message open-file-path screenshot-directory
   ctrl+. script-message open-file-path parent-directory
   ```

## Config

List of configuration options ([`open-file-path.lua`](open-file-path.conf)).

Options can also be configured in `mpv.conf` via `script-opts` using the `open-file-path` prefix.

### command

Default: `xdg-open`

The open command to run.

### args

Additional args for [`command`](#command) (comma-separated by default).

### args_delimiter

Default: `,`

The delimiter for [`args`](#args).

### path_map

Default: `screenshot-directory=@property/screenshot-directory:parent-directory=@computed/parent-directory`

List of key and path pairs separated by a colon (`:`) by default. Example `scripts-opts/open-file-path.lua`:

```conf
path_map=my-path=~/Pictures:screenshot-directory=@property/screenshot-directory:parent-directory=@computed/parent-directory
```

The keys will be passed as an argument to the script message. Example `input.conf`:

```conf
ctrl+S script-message open-file-path screenshot-directory
ctrl+. script-message open-file-path parent-directory
```

### path_map_delimiter

Default: `:`

The delimiter for [`path_map`](#path_map).

#### Computed Paths

List of computed paths that can be used as values for [`path_map`](#path_map).

- `@computed/parent-directory` - Open the parent directory of the current file.

## License

Licensed under the [MIT License](LICENSE).
