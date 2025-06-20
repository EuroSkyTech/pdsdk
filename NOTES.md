# FAQ

## Bindings

### What limitations exists for exposing the internal APIs using wasm-bindgen / uniffi?

Not an exhaustive list but:

- [Async code](https://github.com/mozilla/uniffi-rs/blob/main/docs/manual/src/internals/async-overview.md) is generally supported
- No associated types in traits
- [No generics](https://github.com/mozilla/uniffi-rs/issues/1755) in traits ("simple trait path")
- Dependant types (e.g wrapped errors) [must be exported](https://mozilla.github.io/uniffi-rs/0.29/proc_macro/index.html#types-from-dependent-crates) as well - this probably means we need to cap errors at the FFI level (or provide custom conversions)

For wasm-bindgen additionally:

- No support for [trait impls](https://github.com/rustwasm/wasm-bindgen/issues/2073)

Unrelated to wasm-bindgen, WASM is fundamentally single-threaded which excludes `Send` bounds for async code.

These limitations apply for the external API exposed through the FFI.

## Why are the Swift sources hardlinked into the package?

Currently the toplevel `justfile` uses hardlinks to build the XCFramework structure. While symlinks would show the semantics of this operation much more clearly, _some_ part of the swift package manager fails silently when building frameworks like this. This is visible not when building the package but when testing it (and ofc. in xcode itself which e.g. fails with "Cannot find type 'RustBuffer' in scope").
