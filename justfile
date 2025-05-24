pkg-name := "pdsdk"
pkg-lib-dynamic := "libpdsdk.dylib"
pkg-lib-static := "libpdsdk.a"

apps-ios-open:
    open apps/ios/example.xcodeproj

clean: native-clean pkg-swift-clean

native-build:
    just native-build-target aarch64-apple-darwin
    just native-build-target aarch64-apple-ios
    just native-build-target aarch64-apple-ios-sim
    just native-build-bindings

[working-directory: "pkgs/swift"]
pkg-swift-build: native-build && (pkg-swift-test)
    just pkg-swift-link-target aarch64-apple-darwin
    just pkg-swift-link-target aarch64-apple-ios
    just pkg-swift-link-target aarch64-apple-ios-sim
    plutil -p PdSdkFramework.xcframework/Info.plist

[private, working-directory: "pkgs/swift"]
pkg-swift-test:
    swift build
    swift test

[private, working-directory: "native"]
native-clean:
    cargo clean

[private, working-directory: "native"]
native-build-bindings: native-build-binding-swift native-build-binding-kotlin
    # NOTE: target architecture does not matter for the bindings

[private, working-directory: "native"]
native-build-binding-swift: # NOTE: target architecture does not matter for the bindings
    cargo run --features bindgen --bin bindgen generate --library target/aarch64-apple-darwin/release/{{pkg-lib-static}} --language swift --out-dir target/bindings/ios

[private, working-directory: "native"]
native-build-binding-kotlin:
    cargo run --features bindgen --bin bindgen generate --library target/aarch64-apple-darwin/release/{{pkg-lib-dynamic}} --language kotlin --out-dir target/bindings/android

[private,working-directory: "native/pdsdk"]
native-build-target target: && (native-build-target-size target)
    cargo build --package pdsdk  --target {{target}} --release

[private, working-directory: "native"]
native-build-target-size target:
    @date >> target/{{target}}/release/sizes.txt
    @ls -lh target/{{target}}/release/lib* | awk '{print $9, $5}' | column -t -s " " | tee -a target/{{target}}/release/sizes.txt

[private, working-directory: "pkgs/swift"]
pkg-swift-clean:
    rm -rf .build/
    rm -rf .swiftpm/
    rm -rf PdSdkFramework.xcframework/aarch64*
    rm -f Sources/PdSdk/{{pkg-name}}.swift

[private, working-directory: "pkgs/swift"]
pkg-swift-link-target target:
    mkdir -p Sources/PdSdk
    cd Sources/PdSdk && \
        ln -fw ../../../../native/target/bindings/ios/{{pkg-name}}.swift
    mkdir -p PdSdkFramework.xcframework/{{target}}/headers/PdSdkFramework
    cd PdSdkFramework.xcframework/{{target}} && \
        ln -fw ../../../../native/target/{{target}}/release/{{pkg-lib-static}}
    cd PdSdkFramework.xcframework/{{target}}/headers/PdSdkFramework && \
        ln -fw ../../../../../../native/target/bindings/ios/{{pkg-name}}FFI.modulemap module.modulemap && \
        ln -fw ../../../../../../native/target/bindings/ios/{{pkg-name}}FFI.h

[working-directory: "pkgs/swift"]
pkg-swift-open:
    open Package.swift
