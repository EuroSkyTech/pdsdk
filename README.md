## Installation

Development requirements are currently:

- MacOS on Apple Silicon with [Homebrew](https://brew.sh/)
- [Android Studio](https://developer.android.com/studio), [Caddy](https://caddyserver.com/) and Xcode 16 to work with the Android, WASM and iOS examples respectively
- rust/cargo via [rustup](https://rustup.rs/)
- [just](https://just.systems/man/en/introduction.html)

All followup requirements can the be install with `just deps`.

## Developing

There are currently examples apps available for Android, iOS and Web. Associated tasks can be called through `just` recipes (see also `just --list`):

 - `build` calls the platform specific build recipes (one below) and subsequently calls `build-report` to display some build metadata (such as size)
 - `build-(android|ios|web)` builds platform specific bindings, depends on platform specific target recipes (one below) and subsequently calls platform specific packaging and refresh recipes (two and three below)
- `build-(android|ios|web)-target(arm64-v8a|...|aarch64-apple-ios|...)` builds platform specific targets
- `pkg-(android|ios|web)` builds (and - to some extent - tests) the aar / swift and npm packages respectively
- `app-(android|ios)-refresh` flushes build caches for Android Studio and Xcode (note that any currently open Xcode ContentViews will not directly reflect changes: you need to switch back and forth to see them manifest

Additionally:

- `app-(android|ios|web)-(ide|run)` starts the respective IDE and runs the app (currently only available for web)
- `clean` removes all build artifacts
- `test` runs all native tests
