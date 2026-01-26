# Zig Conway

A terminal-based Conway's Game of Life simulation implemented in Zig ⚡.
Supports configurable matrix size, alive cell probability, mutations, double buffering, ASCII/block rendering, and color support.

```Text
Warning: This program has been tested on modern terminals (Terminal Windows 1.23.13503.0). Older terminals may exhibit slow rendering or display issues when using RGB color mode. For better performance, consider using ANSI mode, or disable inheritance mode for maximum speed.
```

---

## Features

- Configurable life simulation with adjustable:
  - Matrix size (dynamic to terminal)
  - Initial alive probability
  - Mutation frequency, less than 0 to disable
  - Characters modes for rendering
  - Characters colors
- Color inheritance mode allows new cells to inherit or blend colors from parent cells
- Debug mode displaying internal state such as population, generation, memory usage, and seed
- Cross-platform signal handling for clean exit (Windows / Unix/Linux)

---

## Build & Run

### Requirements
- Zig compiler (Tested on 0.15.1)

### Build
```sh
  zig build
```

### Run
```sh
  zig-out/bin/zig-conway [options]
```

---

## Dynamic Matrix Size

The simulation adapts automatically to the size of your terminal window.  

- Number of rows and columns is detected at runtime.
- Resizing the terminal while running adjusts the matrix dimensions dynamically.  
- Ensures the simulation always fills the visible area.

## Command Line Options

| Option | Description | Default | Values |
|--------|-------------|---------|--------|
| `-h`, `--help` | Show the help message | — | — |
| `-v`, `--version` | Show project's version | — | — |
| `-d` | Enable debug mode | Off | — |
| `-hc` | Show the controls map | Off | — |
| `-s` | Random seed | Current timestamp in ms | Any unsigned integer |
| `-ms` | Frame delay in milliseconds | 50 | Any unsigned integer |
| `-l` | Initial alive probability (%) | 0.3 | 0 - 1 |
| `-g` | Mutation generation | -1 | Any unsigned integer (generations before mutating) or less than 0 to disable |
| `-ts` | Symbol mode | Classic |Classic, Treasure, Stars, Dots, Block, Alert, Donut, Twister, Dollar, Euro, Crosshair, Delta, Butterfly, Target, Circle |
| `-cm` | Color mode | RGB | RGB, ANSI |
| `-i` | Enable inheritance mode. Overrides color mode (-c) | Off | — |
| `-if` | Inheritance factions (number of distinct colors in inheritance) | 9 | Any positive integer |
| `-im` | Inheritance mode | Default | Default, Pastel, Neon, Earthy, Cool, Warm, AoE |
| `-c` | Color | White | White, Black, Red, Green, Blue, Yellow, Cyan, Magenta, Orange, Purple, Gray, Pink, Brown, Aqua, Navy, Teal, NeonPink, NeonGreen, NeonBlue, NeonYellow, NeonOrange, NeonPurple, NeonCyan, NeonRed, Lavender, Lime, Coral, Gold |


##  Mutation / Random Impulse

To prevent static states:
 - Mutations invert a small percentage of cells after a defined number of generations.
 - The percentage is proportional to matrix size (0.1%).
 - Configurable via the -g option.

## Color & Rendering

- Supports ASCII or Unicode block characters for alive cells.
- Dead cells are spaces ' '.
- Alive cells can be colored using ANSI escape codes or RGB mode.
- Inheritance mode allows new cells to either:
  - Copy the color of a random neighbor
  - Blend the colors of all alive neighbors
- Example character sets:

| Mode | Alive Char | Dead Char | Notes |
| ---- | ---------- | --------- | ----- |
| Classic | `#` | ` ` | Large ASCII |
| Treasure | `x` | ` ` | Small cross |
| Stars | `*` | ` ` | Medium ASCII |
| Dots | `.` | ` ` | Small dot |
| Block | `█` | ` ` | Unicode block |
| Alert | `!` | ` ` | Attention |
| Donut | `o` | ` ` | Small circle |
| Twister | `@` | ` ` | Symbolic marker |
| Dollar | `$` | ` ` | Dollar symbol |
| Euro | `€` | ` ` | Euro symbol |
| Crosshair | `¤` | ` ` | Target |
| Delta | `∆`  | ` ` | Delta |
| Butterfly | `⌘` | ` ` | Arcane symbol |
| Target | `◎` | ` ` | Circle |
| Circle | `◉` | ` ` | Highlighted circle |

## Color Palettes / Inheritance Modes

Several palettes are included for different visual effects. You can also limit the number of colors selected from a palette using the `-if` (Inheritance Factions) option.

| Palette | Description | Example Colors | Notes |
| ------- | ----------- | -------------- | ----- |
| Default | Standard colors | White, Red, Green, Blue, Yellow, Cyan, Magenta, Orange, Purple | Full default vibrant palette |
| Pastel  Soft, light colors | Pink, Aqua, Teal, Lavender, Light Green | Subtle, soft shades |
| Neon | Bright, glowing colors | NeonRed, NeonGreen, NeonBlue, NeonYellow | High-saturation, luminous colors |
| Earthy | Natural tones | Brown, Green, Orange, Yellow, Gray | Muted, organic colors |
| Cool | Cold palette | Blue, Cyan, Teal, Navy, Purple | Chilly, calming palette |
| Warm | Warm palette | Red, Orange, Yellow, Pink, Gold | Energetic, warm palette |

---

### Examples
#### Run with default settings:

```sh
  zig-out/bin/zig-conway
```

#### Run in debug mode:
```sh
  zig-out/bin/zig-conway -d
```

#### Set custom seed:
```sh
  zig-out/bin/zig-conway -s 1768304672407
```

#### Set custom frame delay:
```sh
  zig-out/bin/zig-conway -ms 150
```

#### Set custom alive probability percentage:
```sh
  zig-out/bin/zig-conway -l 0.50
```

#### Set custom mutation generation frequency:
```sh
  zig-out/bin/zig-conway -g 30
```

#### Use a specific symbol mode:
```sh
  zig-out/bin/zig-conway -sm Stars
```

#### Use a specific color mode:
```sh
  zig-out/bin/zig-conway -cm ANSI
```

#### Use a specific color:
```sh
  zig-out/bin/zig-conway -c NeonPink
```

#### Use a specific inheritance mode:
```sh
  zig-out/bin/zig-conway -im Target
```

---

## Debug Mode

When enabled (-d), the program will print additional runtime information:
- Project name and version
- Memory usage (persistent & scratch)
- Execution parameters: speed, alive probability, mutation generation, mode, color
- Random seed and matrix dimensions
- Population of alive cells per generation

---

## Interactive Controls

The simulation supports real-time key input. This allows you to interactively pause, reload, or exit the simulation while it is running.

| Key | Action |
| --- | ------ |
| `p`, `Space` | Toggle pause/resume. When paused, the simulation stops updating the matrix but the display remains visible. Pressing again resumes the simulation. |
| `r`, `Backspace` | Reload the current matrix. **Only the matrix is reset**; random components such as the LCG or color generator are not reinitialized. Useful to refresh the simulation state without affecting the random sequence. |
| `+` | Increases the current sleep time by 10 ms, up to a maximum of 3000 ms (3 seconds). |
| `-` | Decreases the current sleep time by 10 ms, down to a minimum of 0 ms. |
| `q`, `CTRL+C` | Exit the simulation cleanly. |

### Notes

- Input is handled asynchronously in a separate thread, so the simulation continues rendering frames even while waiting for a keypress.
- Pause, reload, and exit are implemented using atomic flags, ensuring safe concurrent access between the input thread and the render loop.
- Works on Windows, Linux, and macOS, with platform-specific raw mode setup to ensure immediate key detection.


---
