## Installation

Development requirements are currently:

- MacOS on Apple Silicon
- [Android Studio](https://developer.android.com/studio) and Xcode 16
- [Homebrew](https://brew.sh/)
- rust/cargo via [rustup](https://rustup.rs/)
- [just](https://just.systems/man/en/introduction.html)

All followup requirements can the be install with `just install-dependencies`.

## Developing

There are currently examples apps available for Android and iOS. You can open them using `just apps-ios-open` and `just apps-android-open` respectively.

Calling `just build` will update the native dependencies and clean the respective build caches.
