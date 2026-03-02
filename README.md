# foundry.nvim

Forge your code without leaving Neovim — complete build, run, and debug workflow.

## Features

- **Build System Integration** - Seamless workflow for building and running projects
- **Debugger Support** - Integrated debugging workflow with DAP
- **Persistent Notifications** - Real-time feedback with spinner animations for long-running operations
- **Smart Project Detection** - Automatically detects project type and configures available actions
- **Test Integration** - Discovery and execution of tests with test-specific debugging
- **Module-Based Architecture** - Extensible design supporting multiple build systems (CMake first, more coming)

## Requirements

Foundry works out of the box with no required dependencies. However, optional integrations enhance the experience:

**Recommended:**
- [fidget.nvim](https://github.com/j-hui/fidget.nvim) - Beautiful notifications with spinner animations
- [overseer.nvim](https://github.com/stevearc/overseer.nvim) - Enhanced task runner with UI

**For CMake projects:**
- CMake 3.19+ (for presets support)
- C/C++ compiler toolchain

## Installation

### lazy.nvim
```lua
{
  'bransay/foundry.nvim',
  dependencies = {
    'j-hui/fidget.nvim',        -- Optional but recommended
    'stevearc/overseer.nvim',   -- Optional but recommended
  },
  config = function()
    require('foundry').setup()
  end,
}
```

### packer.nvim
```lua
use {
  'bransay/foundry.nvim',
  config = function()
    require('foundry').setup()
  end,
}
```

### vim-plug
```vim
Plug 'bransay/foundry.nvim'

" In your init.vim or init.lua
lua require('foundry').setup()
```

## Setup

Minimal setup with defaults:

```lua
require('foundry').setup()
```

### Custom Configuration

All options are optional. Foundry provides sensible defaults.

```lua
require('foundry').setup({
  -- Custom task runner (defaults to vim.system if overseer not available)
  task = function(name, cmd, cwd)
    -- Your custom task implementation
    -- Return true on success, false on failure
  end,
})
```

## Usage

### Opening the Menu

Run `:Foundry` with no arguments to open the interactive menu:

```vim
:Foundry
```

The menu displays available actions based on your detected project type.

### Command Shortcuts

You can also run actions directly:

```vim
:Foundry Generate      " Configure the project
:Foundry Build         " Build selected target
:Foundry Build All     " Build all targets
:Foundry Run           " Run the executable
:Foundry Debug         " Debug the executable
:Foundry Test          " Run tests
:Foundry Debug Test    " Debug a specific test
:Foundry Options       " Configure settings
```

Tab completion is available for all subcommands.

## CMake Workflow

Foundry currently supports CMake projects out of the box. Here's a typical workflow:

### 1. Open Your Project

Open any directory containing a `CMakeLists.txt` file. Foundry automatically detects it as a CMake project.

### 2. Generate the Build

```vim
:Foundry Generate
```

Select a preset when prompted. Foundry creates the build directory and configures the project.

### 3. Build Your Code

```vim
:Foundry Build
```

Select a target to build. Foundry shows a spinning notification during the build process.

### 4. Run or Debug

```vim
:Foundry Run    " Run the executable
:Foundry Debug  " Launch the debugger
```

### 5. Run Tests

```vim
:Foundry Test       " Run a specific test
:Foundry Debug Test " Debug a test with full debugger
```

### Configuration Options

Run `:Foundry Options` to configure:

- **Build Directory** - Where build artifacts are stored (default: `build/<preset>`)
- **Preset** - CMake preset to use
- **Target** - Default build target
- **Executable Path** - Path to the built executable
- **Executable Arguments** - Command-line arguments for run/debug
- **Debugger Language** - Language for debugger (C++, C, etc.)
- **Build Before Run** - Automatically rebuild before running

## Integrations

### Fidget.nvim

When fidget.nvim is installed, Foundry uses it for all notifications:

- **Persistent notifications** - Long-running operations stay visible until completion, so you know immediately when a task is still running
- **Grouped notifications** - All Foundry messages are grouped together under the anvil icon (󰢛), keeping them separate from other plugin notifications

Without fidget, Foundry falls back to Neovim's built-in `vim.notify()`.

### Overseer.nvim

When overseer.nvim is installed, Foundry uses it as the task runner for better task management and output handling.

Without overseer, Foundry uses a simple `vim.system()`-based runner.

## Architecture

Foundry is designed as a modular framework:

- **Core** (`init.lua`, `commands.lua`) - Command registration and initialization
- **Project Detection** (`discover.lua`) - Automatic project type detection
- **Modules** (`cmake.lua`, etc.) - Build system-specific implementations
- **Notifications** (`notify.lua`) - Unified notification interface with backend detection
- **Options** (`options.lua`) - Configuration and user prompts

## Coming Soon

- Additional build system support (Make, Meson, etc.)
- Enhanced task UI integration
- More debugging features
- Workspace/multi-project support

## License

MIT
