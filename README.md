# mpv-open-file-path

Open file path in [mpv](https://mpv.io/).

## Install

Download the following files to their appropriate directories under your mpv config (e.g., `~/.config/mpv`):

[`open-file-path.lua`](open-file-path.lua) - Save to `scripts` directory.

```sh
wget github.com/Arnesfield/mpv-open-file-path/raw/main/open-file-path.lua
```

[`open-file-path.conf`](open-file-path.conf) - Save to `script-opts` directory. Includes defaults.

```sh
wget github.com/Arnesfield/mpv-open-file-path/raw/main/open-file-path.conf
```

## Usage

Use `script-message open-file-path <path>` in your `input.conf`. Example:

```conf
ctrl+/ script-message open-file-path ~/Videos
/ script-message open-file-path @computed/parent-directory
ctrl+. script-message open-file-path @property/path
ctrl+S script-message open-file-path @property/screenshot-directory
```

### Properties as Paths

Paths prefixed with `@property/` (e.g., `@property/<property-key>`) can be used to treat the value from `mp.get_property('<property-key>')` as a file path to open.

### Computed Paths

Paths prefixed with `@computed/` are hardcoded:

- `@computed/parent-directory` - Open the parent directory of the current file.

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

## License

Licensed under the [MIT License](LICENSE).
