android-build-tools := "35.0.1"
android-home := "/opt/homebrew/share/android-commandlinetools"
android-platform := "35"
android-ndk := "28.1.13356709"

ios-xcode := "16.2"

pkg-name := "pdsdk"
pkg-lib-dynamic := "libpdsdk.dylib"
pkg-lib-static := "libpdsdk.a"

export ANDROID_HOME := android-home
export ANDROID_SDK_ROOT := android-home
export ANDROID_NDK_HOME := android-home + "/ndk/" + android-ndk
export JAVA_HOME := "/opt/homebrew/opt/openjdk@17"

apps-android:
    open apps/android -a "Android Studio"

apps-ios-open:
    open apps/ios/example.xcodeproj

build: pkg-aar-build pkg-swift-build

clean: native-clean pkg-aar-clean pkg-swift-clean

native-build:
    just native-build-target aarch64-apple-darwin
    just native-build-target aarch64-apple-ios
    just native-build-target aarch64-apple-ios-sim
    just native-build-target-android
    just native-build-bindings

install-dependencies:
    #!/bin/sh
    set -eo pipefail

    brew install --cask temurin
    brew install android-commandlinetools gawk openjdk@17

    cargo install cargo-ndk

    yes | sdkmanager --licenses || true
    sdkmanager --install "build-tools;{{ android-build-tools }}" --verbose
    sdkmanager --install "platforms;android-{{ android-platform }}" --verbose
    sdkmanager --install "platform-tools" --verbose
    sdkmanager --install "ndk;{{ android-ndk }}" --verbose
    sdkmanager --install "system-images;android-{{ android-platform }};google_apis;arm64-v8a" --verbose

    if [ "$GITHUB_ACTIONS" = "true" ]; then
        sudo xcode-select -switch /Applications/Xcode_{{ ios-xcode }}.app/Contents/Developer
    fi

[working-directory("pkgs/aar")]
pkg-aar-build: native-build && pkg-aar-test pkg-aar-build-clean
    just pkg-aar-link
    ./gradlew publishToMavenLocal

[working-directory("pkgs/swift")]
pkg-swift-build: native-build && pkg-swift-test pkg-swift-build-clean
    just pkg-swift-link-target aarch64-apple-darwin
    just pkg-swift-link-target aarch64-apple-ios
    just pkg-swift-link-target aarch64-apple-ios-sim

[working-directory("pkgs/swift")]
pkg-swift-open:
    open Package.swift

[private]
[working-directory("native")]
native-clean:
    cargo clean

[private]
[working-directory("native")]
native-build-bindings: native-build-binding-swift native-build-binding-kotlin
    # NOTE: target architecture does not matter for the bindings

[private]
[working-directory("native")]
native-build-binding-swift:
    cargo run --features bindgen --bin bindgen generate --library target/aarch64-apple-darwin/release/{{ pkg-lib-static }} --language swift --out-dir target/bindings/ios

[private]
[working-directory("native")]
native-build-binding-kotlin:
    cargo run --features bindgen --bin bindgen generate --library target/aarch64-apple-darwin/release/{{ pkg-lib-dynamic }} --language kotlin --out-dir target/bindings/android/kotlin

[private]
[working-directory("native")]
native-build-target-android:
    cargo ndk -t armeabi-v7a -t arm64-v8a -t x86 -t x86_64 -p {{ android-platform }} -o target/bindings/android/jniLibs build --release --package pdsdk

[private]
[working-directory("native/pdsdk")]
native-build-target target: && (native-build-target-size target)
    cargo build --package pdsdk  --target {{ target }} --release

[private]
[working-directory("native")]
native-build-target-size target:
    @date >> target/{{ target }}/release/sizes.txt
    @ls -lh target/{{ target }}/release/lib* | awk '{print $9, $5}' | column -t -s " " | tee -a target/{{ target }}/release/sizes.txt

[private]
[working-directory("apps/android")]
pkg-aar-build-clean:
    ./gradlew clean --refresh-dependencies --rerun-tasks

[private]
[working-directory("pkgs/aar")]
pkg-aar-clean:
    rm -rf src/main

[private]
[working-directory("pkgs/aar")]
pkg-aar-link:
    mkdir -p src/main
    cp -rf ../../native/target/bindings/android/* src/main/

[private]
[working-directory("pkgs/aar")]
pkg-aar-test:
    gradle build
    # FIXME: no "hello world" test yet - cargo ndk does not support darwin-aarch64 and native dylibs do not use the appropriate JNI symbols (prefixed with Java_namespace_methodname)

[private]
[working-directory("apps/ios")]
pkg-swift-build-clean:
    xcodebuild clean -project example.xcodeproj -alltargets

[private]
[working-directory("pkgs/swift")]
pkg-swift-clean:
    rm -rf .build/
    rm -rf .swiftpm/
    rm -rf PdSdkFramework.xcframework/aarch64*
    rm -f Sources/PdSdk/{{ pkg-name }}.swift

[private]
[working-directory("pkgs/swift")]
pkg-swift-link-target target:
    mkdir -p Sources/PdSdk
    cd Sources/PdSdk && \
        ln -fw ../../../../native/target/bindings/ios/{{ pkg-name }}.swift
    mkdir -p PdSdkFramework.xcframework/{{ target }}/headers/PdSdkFramework
    cd PdSdkFramework.xcframework/{{ target }} && \
        ln -fw ../../../../native/target/{{ target }}/release/{{ pkg-lib-static }}
    cd PdSdkFramework.xcframework/{{ target }}/headers/PdSdkFramework && \
        ln -fw ../../../../../../native/target/bindings/ios/{{ pkg-name }}FFI.modulemap module.modulemap && \
        ln -fw ../../../../../../native/target/bindings/ios/{{ pkg-name }}FFI.h

[private]
[working-directory("pkgs/swift")]
pkg-swift-test:
    swift build
    swift test
