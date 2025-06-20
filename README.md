## Installation

Development requirements are currently:

- MacOS on Apple Silicon with [Homebrew](https://brew.sh/)
- [Android Studio](https://developer.android.com/studio), [Caddy](https://caddyserver.com/) and Xcode 16 to work with the Android, WASM and iOS examples respectively
- rust/cargo via [rustup](https://rustup.rs/)
- [just](https://just.systems/man/en/introduction.html)

All followup requirements can the be install with `just install-dependencies`.

## Developing

There are currently examples apps available for Android, iOS and WASM. You can open them using `just apps-android-open`, `just apps-ios-open` and `just apps-wasm-open` respectively.

Calling `just build` will update the native dependencies and clean the respective build caches (not needed for WASM).

The WASM app can be started using `just apps-wasm-run`. All other apps can be locally tested using the respective emulators.
