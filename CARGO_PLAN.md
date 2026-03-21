# Cargo Support Implementation Plan

## Step 1: Detection + Registration ✅ DONE

- Create `lua/foundry/cargo.lua`
- `detect(root)` checks for `Cargo.toml`
- Register module in `discover.lua`

## Step 2: Core Actions (No Debug) - IN PROGRESS

### Options ✅ DONE
- `PROFILE` ✅ - Built-in profiles (dev/release/test/bench) + user-defined input via picker composition
- `TARGET` ✅ - Binary picker via `cargo metadata --format-version=1 --no-deps`, filters for `kind: ["bin"]`
- `EXECUTABLE_ARGUMENTS` - Not needed for MVP
- `BUILD_BEFORE_RUN` - Not needed (cargo handles automatically)

### Actions
- `options()` ✅ - Configure settings
- `build()` ✅ - `cargo build --profile <profile> --bin <target>` with spinner notification
- `build_all()` ✅ - `cargo build --profile <profile> --all-targets` with spinner notification
- `check()` ✅ - `cargo check --profile <profile>` with spinner notification
- `run()` ❌ - Not implemented
- `test()` ❌ - Not implemented

### Implementation Notes

**Profile Picker:**
- Uses `select_picker` + fallback to `input_picker` for "User-defined"
- Built-ins: dev, release, test, bench
- No metadata required - profiles are defined in Cargo.toml

**Target Picker:**
- Queries `cargo metadata --format-version=1 --no-deps`
- Parses `packages[].targets[]` and filters for `kind: ["bin"]`
- Returns sorted list of binary target names

**Build Flow:**
- `get_build_context()` - Gets required PROFILE and TARGET options (prompts user if not set)
- `setup_opts.task()` - Runs cargo command via configured task runner
- Spinner notification during build, success/failure on completion

## Step 3: Remaining Actions

### run()
- `cargo run --bin <target> --profile <profile> [-- args]`
- Reuse build context? Add EXECUTABLE_ARGUMENTS option?

### test()
- `cargo test [<testname>]`
- Test picker: `cargo test -- --list` to discover tests? Or input picker?

## Future

- `debug()` - Build + DAP launch
- `debug_test()` - Debug specific test