# Cargo Support Implementation Plan

## Step 1: Detection + Registration ✅ DONE

- Create `lua/foundry/cargo.lua`
- `detect(root)` checks for `Cargo.toml`
- Register module in `discover.lua`

## Step 2: Core Actions ✅ DONE

### Options ✅ DONE
- `PROFILE` ✅ - Built-in profiles (dev/release/test/bench) + user-defined input via picker composition
- `TARGET` ✅ - Binary picker via `cargo metadata --format-version=1 --no-deps`, filters for `kind: ["bin"]`
- `EXECUTABLE_PATH` ✅ - File picker for manual override, default computed from profile + target
- `EXECUTABLE_ARGUMENTS` ✅ - String input for CLI args
- `BUILD_BEFORE_RUN` ✅ - Boolean picker, default `true`

### Actions ✅ DONE
- `options()` ✅ - Configure settings
- `build()` ✅ - `cargo build --profile <profile> --bin <target>` with spinner notification
- `build_all()` ✅ - `cargo build --profile <profile> --all-targets` with spinner notification
- `check()` ✅ - `cargo check --profile <profile>` with spinner notification
- `clean()` ✅ - `cargo clean` with spinner notification
- `run()` ✅ - `cargo run --profile <profile> --bin <target>` (fire-and-forget)
- `test()` ✅ - `cargo test --profile <profile>` with spinner notification
- `debug()` ✅ - Build + DAP launch

### Implementation Notes

**Profile Picker:**
- Uses `select_picker` + fallback to `input_picker` for "User-defined"
- Built-ins: dev, release, test, bench
- No metadata required - profiles are defined in Cargo.toml

**Target Picker:**
- Queries `cargo metadata --format-version=1 --no-deps`
- Parses `packages[].targets[]` and filters for `kind: ["bin"]`
- Returns sorted list of binary target names

**Executable Path Computation:**
- `get_default_executable_path(profile, target)` computes path
- Queries cargo metadata for `target_directory`
- Maps profile to directory: dev/test → debug, release/bench → release, custom → custom
- Appends `.exe` on Windows
- User can override via `EXECUTABLE_PATH` option

**Build Flow:**
- `get_build_context()` - Gets required PROFILE and TARGET options (prompts user if not set)
- `setup_opts.task()` - Runs cargo command via configured task runner
- Spinner notification during build, success/failure on completion

**Debug Flow:**
- Gets profile/target via `get_build_context()`
- Computes executable path (default from metadata, or override from options)
- Optionally builds first (BUILD_BEFORE_RUN, default: true)
- Launches via `foundry.debug` module with `'rust'` filetype

## Future

- `debug_test()` - Debug specific test