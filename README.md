# mpv-run

Run commands in [mpv](https://mpv.io/) via `script-message`.

## Install

Download the following files to their appropriate directories under your mpv config (e.g., `~/.config/mpv`):

[`run.lua`](run.lua) - Save to `scripts` directory.

```sh
wget github.com/Arnesfield/mpv-run/raw/main/run.lua
```

[`run.conf`](run.conf) - Save to `script-opts` directory. Includes defaults.

```sh
wget github.com/Arnesfield/mpv-run/raw/main/run.conf
```

## Usage

By default, the command is `xdg-open` which can be configured through the [`command`](#command) option.

Use `script-message run <arg>` to run the command with the specified argument.

Example `input.conf`:

```conf
# raw and with modifiers
ctrl+?  script-message run '/absolute/path/to my directory'
ctrl+/  script-message run @raw.path/~/Videos

# computed (with modifiers)
/       script-message run @computed.path/parent-directory

# property (with modifiers)
ctrl+.  script-message run @property.path/path
ctrl+S  script-message run @property.path/screenshot-directory

# run command (ignores default command)
ctrl+>  script-message run-cmd gio open :@property.path/screenshot-directory
```

### Script Messages

Below are the list of registered script messages once this script is applied.

#### run

Runs the configured [`command`](#command) with the provided argument.

```sh
script-message run @property.path/screenshot-directory
```

#### run-cmd

Runs command using the provided arguments (the configured [`command`](#command) is ignored).

```sh
script-message run-cmd gio open :@property.path/screenshot-directory /tmp
```

Note that only arguments that start with a colon (`:`) will be substituted. Otherwise, they will be treated as raw arguments.

#### run-parse

Parses arguments into their equivalent values when substituted. Raw values are returned as is.

```sh
script-message run-parse @property/screenshot-directory
```

### Substitutions

The following patterns are used for substitution.

- `@raw/{value}` - Use the `{value}` as is. Usually used with [modifiers](#modifiers).
- `@var/{key}` - Use the associated value of the provided `{key}` from the [`vars`](#vars) option.
- `@property/{key}` - Get the property via `mp.get_property('{key}')`.
- `@computed/{key}` - Use the computed value. See the list of [computed properties](#computed-properties).

### Modifiers

Modifiers can be added to transform the value.

Format:

```text
@var[.modifier[.modifiers...]]/{value}
```

List of available modifiers:

- `path` - Transforms the value with: `mp.command_native({ 'expand-path', value })`

Example `input.conf`:

```conf
ctrl+/ script-message run @raw.path/~/Videos
```

> [!NOTE]
>
> Feel free to suggest/implement new modifiers!

### Computed Properties

List of available computed properties:

- `parent-directory` - The parent directory of the current file.

Example `input.conf`:

```conf
/ script-message run @computed.path/parent-directory
```

> [!NOTE]
>
> Feel free to suggest/implement new computed properties!

### Variables

By configuring the [`vars`](#vars) key-value pairs, you can use the keys as placeholder values.

Example:

```conf
# mpv.conf
script-opts-append=run-vars=command=xdg-open,videos-dir=~/Videos

# input.conf
/ script-message run-cmd :command :@var.path/videos-dir
```

## Config

List of configuration options ([`run.lua`](run.conf)).

Options can also be configured in `mpv.conf` via `script-opts` using the `run` prefix.

### command

Default: `xdg-open`

The command to run by default for non-command mode calls. Required for non-command mode calls.

### vars

Default: `command=xdg-open`

List of key-value pair variables separated by a comma by default.

### vars_delimiter

Default: `,`

The delimiter for [`vars`](#vars).

## License

Licensed under the [MIT License](LICENSE).
