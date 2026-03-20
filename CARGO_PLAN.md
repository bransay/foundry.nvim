# Cargo Support Implementation Plan

## Step 1: Detection + Registration ✅ DONE

- Create `lua/foundry/cargo.lua`
- `detect(root)` checks for `Cargo.toml`
- Register module in `discover.lua`

## Step 2: Core Actions (No Debug) - IN PROGRESS

### Options ✅ Partial
- `PROFILE` ✅ - Built-in profiles (dev/release/test/bench) + user-defined input
- `TARGET` ✅ - Binary picker via `cargo metadata --format-version=1 --no-deps`
- `EXECUTABLE_ARGUMENTS` ❌ - Not yet
- `BUILD_BEFORE_RUN` ❌ - Not needed for cargo (handles automatically)

### Actions
- `options()` ✅ - Configure settings (works)
- `build()` ⏳ - Stub only (prints notification)
- `build_all()` ❌ - Not stubbed
- `run()` ❌ - Not stubbed
- `test()` ❌ - Not stubbed

### Implementation Notes

**Profile Picker:**
- Uses `select_picker` + fallback to `input_picker` for "User-defined"
- Built-ins: dev, release, test, bench
- No metadata required - profiles are defined in Cargo.toml

**Target Picker:**
- Queries `cargo metadata --format-version=1 --no-deps`
- Parses `packages[].targets[]` and filters for `kind: ["bin"]`
- Returns sorted list of binary target names

## Future

- `debug()` - Build + DAP launch
- `debug_test()` - Debug specific test