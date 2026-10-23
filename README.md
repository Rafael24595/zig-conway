# Zig Conway

A configurable, terminal-based implementation of Conway's Game of Life written in Zig. ⚡

Customize the simulation with different cell symbols, color palettes, color inheritance, and mutation settings. The matrix adapts to the terminal dimensions and uses buffered rendering to display each generation.

> **Terminal compatibility:** The project has been tested with Windows Terminal 1.23.13503.0. Character rendering and performance may vary across terminal emulators. If RGB rendering is slow, try ANSI mode or disable inheritance mode.

## Features

- **Configurable simulation:** Set the initial alive-cell probability, frame delay, random seed, and mutation interval.
- **Dynamic matrix sizing:** Adapt the matrix to the terminal dimensions and reload it when the window is resized.
- **Cell symbol themes:** Choose from ASCII and Unicode symbols, including blocks, dots, stars, and other shapes.
- **Color modes:** Render cells using RGB or ANSI terminal colors.
- **Color inheritance:** New cells can inherit a neighboring color or blend the colors of their living neighbors.
- **Color palettes:** Choose from Default, Pastel, Neon, Earthy, Cool, and Warm palettes.
- **Mutation:** Periodically invert a small proportion of cells to introduce new patterns. Set a negative mutation generation to disable mutations.
- **Debug mode:** Inspect runtime configuration, matrix dimensions, population, generation, and memory usage.
- **Interactive controls:** Pause, reload, adjust the frame delay, or exit while the simulation is running.
- **Terminal cleanup:** Restore the cursor and terminal state during normal shutdown.

## Requirements

- Zig compiler 0.15.1 (tested version).
- A terminal emulator with ANSI escape-sequence support.
- UTF-8 support for Unicode symbol themes.

## Build

Build the project:

```sh
zig build
```

Build an optimized release version:

```sh
zig build -Doptimize=ReleaseFast
```

`ReleaseFast` prioritizes runtime performance over debug-friendly behavior.

## Run

Launch the executable:

```sh
zig-out/bin/zig-conway
```

Display the available command-line options:

```sh
zig-out/bin/zig-conway --help
```

## Command-Line Options

| Option | Description | Default |
|---|---|---|
| `-h`, `--help` | Display the help message | — |
| `-v`, `--version` | Display the project version | — |
| `-d` | Enable debug output | Disabled |
| `-hc` | Display the interactive controls map | Disabled |
| `-s` | Set the random seed | Current timestamp in milliseconds |
| `-ms` | Set the frame delay in milliseconds | `45` ms on Windows; `50` ms on other platforms |
| `-l` | Set the initial probability that a cell is alive | `0.3` |
| `-g` | Set the mutation interval in generations; a negative value disables mutations | `-1` |
| `-ts` | Set the cell symbol theme | `classic` |
| `-cm` | Set the color format | `rgb` |
| `-i` | Enable color inheritance; overrides the regular color setting | Disabled |
| `-if` | Set the number of colors used for inheritance | `9` |
| `-im` | Set the inheritance color palette | `default` |
| `-c` | Set the cell color when inheritance is disabled | `white` |

Run `zig-out/bin/zig-conway --help` for the exact syntax and accepted values supported by your build.

### Available symbol themes (`-ts`)

`classic`, `treasure`, `stars`, `dots`, `block`, `alert`, `donut`, `twister`, `dollar`, `euro`, `crosshair`, `delta`, `butterfly`, `tango`, `circle`.

| Theme | Alive symbol | Dead symbol |
|---|---|---|
| `classic` | `#` | Space |
| `treasure` | `x` | Space |
| `stars` | `*` | Space |
| `dots` | `.` | Space |
| `block` | `█` | Space |
| `alert` | `!` | Space |
| `donut` | `o` | Space |
| `twister` | `@` | Space |
| `dollar` | `$` | Space |
| `euro` | `€` | Space |
| `crosshair` | `¤` | Space |
| `delta` | `∆` | Space |
| `butterfly` | `⌘` | Space |
| `tango` | `◎` | Space |
| `circle` | `◉` | Space |

### Available color modes (`-cm`)

- `rgb` — true-color ANSI escape sequences.
- `ansi` — 256-color terminal palette.

### Available inheritance palettes (`-im`)

- `default`
- `pastel`
- `neon`
- `earthy`
- `cool`
- `warm`

### Available colors (`-c`)

`white`, `black`, `red`, `green`, `green_dark`, `green_medium`, `green_bright`, `green_olive`, `green_moss`, `blue`, `yellow`, `cyan`, `magenta`, `orange`, `purple`, `deep_purple`, `hot_purple`, `gray`, `gray_dark`, `gray_light`, `pink`, `brown`, `aqua`, `navy`, `teal`, `lavender`, `pale_lavender`, `violet`, `lime`, `coral`, `gold`, `neon_pink`, `neon_green`, `neon_blue`, `neon_yellow`, `neon_orange`, `neon_purple`, `neon_cyan`, `neon_red`

## Examples

Run with the default settings:

```sh
zig-out/bin/zig-conway
```

Enable debug output:

```sh
zig-out/bin/zig-conway -d
```

Set a custom random seed:

```sh
zig-out/bin/zig-conway -s 1768304672407
```

Change the frame delay to 150 milliseconds:

```sh
zig-out/bin/zig-conway -ms 150
```

Set the initial alive-cell probability to `0.5`:

```sh
zig-out/bin/zig-conway -l 0.5
```

Mutate the matrix every 30 generations:

```sh
zig-out/bin/zig-conway -g 30
```

Disable mutations:

```sh
zig-out/bin/zig-conway -g -1
```

Use block symbols:

```sh
zig-out/bin/zig-conway -ts block
```

Use ANSI colors:

```sh
zig-out/bin/zig-conway -cm ansi
```

Use a neon color:

```sh
zig-out/bin/zig-conway -c neon_pink
```

Enable color inheritance with the Neon palette:

```sh
zig-out/bin/zig-conway -i -im neon
```

Combine multiple options:

```sh
zig-out/bin/zig-conway -l 0.5 -g 30 -ts stars -cm ansi
```

## Color and Rendering

Living cells are rendered using the selected symbol and color settings. Dead cells are rendered as spaces.

RGB mode uses true-color escape sequences. ANSI mode maps RGB values to the 256-color terminal palette and may perform better in some terminal emulators.

When inheritance is enabled, newly born cells receive colors based on their living neighbors. Depending on the configured inheritance behavior, the color may be selected from a neighbor or blended from multiple neighboring colors. The `-if` option limits the number of colors sampled from the selected palette.

A dark terminal background is recommended for the intended visual style and contrast.

## Mutation

Mutation introduces random changes to the simulation after the configured number of generations. The mutation count is proportional to matrix size, with a target of approximately 0.1% of the cells per mutation event and at least one attempted mutation.

Use `-g` to set the interval. A negative value disables mutations.

## Dynamic Matrix Size

The application detects the terminal dimensions and builds the matrix to fit the available area. If the terminal is resized, the render loop requests a reload so the matrix can be rebuilt for the new dimensions.

## Debug Mode

Enable debug output with `-d` to inspect runtime information, including:

- Project name and version.
- Persistent and scratch memory usage.
- Frames per second (FPS)
- Frame delay in milliseconds
- Random seed 
- Initial alive-cell probability.
- Mutation interval.
- Symbol theme and color configuration.
- Matrix dimensions
- Living-cell population.
- Generation information, where available in the current debug output.

## Interactive Controls

The simulation accepts keyboard input while running.

| Key | Action |
|---|---|
| `p`, `Space` | Toggle pause and resume. The current frame remains visible while paused. |
| `r`, `Backspace` | Request a matrix reload and reset the start timestamp. The random generator is not reinitialized. |
| `+` | Increase the frame delay by 10 ms, up to 3000 ms. |
| `-` | Decrease the frame delay by 10 ms, down to 0 ms. |
| `q`, `Ctrl+C` | Request a clean exit. |

Input is processed on a separate thread, allowing the render loop to continue while waiting for key presses. Runtime flags use atomic operations to coordinate input and rendering.

## Shutdown and Signal Handling

The application installs a signal handler and requests shutdown when an interrupt is received. During normal shutdown, cleanup routines attempt to restore the cursor and clear terminal output. Exact behavior may depend on the operating system, terminal emulator, and how the process terminates.
