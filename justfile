android-build-tools := "35.0.1"
android-home := "/opt/homebrew/share/android-commandlinetools"
android-platform := "35"
android-ndk := "28.1.13356709"

editor := "${VISUAL:-${EDITOR:?Neither VISUAL nor EDITOR configured}}"

ios-xcode := "16.2"

pkg-name := "pdsdk"
pkg-lib-dynamic := "libpdsdk.dylib"
pkg-lib-static := "libpdsdk.a"

report-dir := "target/report/" + datetime("%Y%m%d-%H%M%S")

web-port := "3000"

export ANDROID_HOME := android-home
export ANDROID_SDK_ROOT := android-home
export ANDROID_NDK_HOME := android-home + "/ndk/" + android-ndk
export JAVA_HOME := "/opt/homebrew/opt/openjdk@17"

# APPS - DEVELOPMENT SUPPORT

[doc("Open the Android application in Android Studio")]
app-android-ide:
    open apps/android -a "Android Studio"

[doc("Refresh dependencies in the Android application")]
[working-directory("apps/android")]
app-android-refresh:
    ./gradlew clean --refresh-dependencies --rerun-tasks

[doc("Open the iOS application in xcode")]
app-ios-ide:
    open apps/ios/example.xcodeproj

[doc("Refresh dependencies in the iOS application")]
[working-directory("apps/ios")]
app-ios-refresh:
    xcodebuild clean -project example.xcodeproj -alltargets

[doc("Open the web application in your IDE")]
app-web-ide:
    {{ editor }} apps/web

[doc("Run and open the web application")]
[working-directory("apps/web")]
app-web-run:
    #!/bin/sh
    set -eo pipefail
    [ -f tmp/caddy.pid ] && kill $(cat tmp/caddy.pid)
    CADDY_PORT={{ web-port }} caddy start --pidfile tmp/caddy.pid
    open https://localhost:{{ web-port }}

# BUILD

[doc("Build for all platforms")]
build: build-android build-ios build-web && build-report

[doc("Build for the Android platform")]
[working-directory("native")]
build-android: (build-android-target "armeabi-v7a") (build-android-target "arm64-v8a") (build-android-target "x86") (build-android-target "x86_64") && pkg-android app-android-refresh
    # the architecture does not matter for running bindgen - but we need the dynamic library to be present
    cargo build --features bindgen
    cargo run --features bindgen --bin bindgen generate --library target/debug/{{ pkg-lib-dynamic }} --language kotlin --out-dir target/bindings/android/kotlin

[private]
[working-directory("native")]
build-android-target target:
    cargo ndk -t {{ target }} -p {{ android-platform }} -o target/bindings/android/jniLibs build --release --package pdsdk

[doc("Build for the iOS platform")]
[working-directory("native")]
build-ios: (build-ios-target "aarch64-apple-darwin") (build-ios-target "aarch64-apple-ios") (build-ios-target "aarch64-apple-ios-sim") && pkg-ios app-ios-refresh
    cargo build --features bindgen
    cargo run --features bindgen --bin bindgen generate --library target/aarch64-apple-darwin/release/{{ pkg-lib-static }} --language swift --out-dir target/bindings/ios

[private]
[working-directory("native")]
build-ios-target target:
    cargo build --package pdsdk  --target {{ target }} --release

[doc("Report on build targets sizes and bloat")]
[working-directory("native")]
build-report:
    #!/bin/sh
    mkdir -p {{ report-dir }}
    targets=$(just build-targets)

    export RUSTFLAGS="-A warnings"

    echo "Native bloat\n\n"
    cargo bloat --release --package {{ pkg-name }} | tee {{ report-dir }}/bloat-darwin.txt

    for target in $targets; do
        echo "\nTrees for $target\n"
        cargo tree --edges normal --package {{ pkg-name }} --target $target | tee {{ report-dir }}/trees-$target.txt

        echo "\nSizes for $target\n"
        ls -lh target/$target/release/lib* | awk '{print $9, $5}' | column -t -s " " | tee {{ report-dir }}/sizes-$target.txt
    done

    echo "\nWASM sizes\n"
    ls -lh target/bindings/wasm/*.wasm* | awk '{print $9, $5}' | column -t -s " " | tee {{ report-dir }}/sizes-wasm.txt

[doc("Build for the Web platform")]
[working-directory("native")]
build-web: && pkg-web
    CARGO_PROFILE_RELEASE_STRIP=false wasm-pack build --target web --release --out-dir ../target/bindings/wasm pdsdk

# CLEAN

[doc("Clean build artefacts")]
[working-directory("native")]
clean: && clean-android clean-ios clean-web
    cargo clean

[private]
[working-directory("pkgs/aar")]
clean-android:
    rm -rf src/main

[private]
[working-directory("pkgs/swift")]
clean-ios:
    rm -rf .build/
    rm -rf .swiftpm/
    rm -rf PdSdkFramework.xcframework/aarch64*
    rm -f Sources/PdSdk/{{ pkg-name }}.swift

[private]
[working-directory("pkgs/npm")]
clean-web:
    rm *

# DEPENDENCIES

[doc("Install all dependencies except those stated in the README")]
deps: deps-android deps-ios deps-web
    brew install llvm --force # required for ring

[private]
deps-android:
    brew install android-commandlinetools gawk openjdk@17

    yes | sdkmanager --licenses || true
    sdkmanager --install "build-tools;{{ android-build-tools }}" --verbose
    sdkmanager --install "platforms;android-{{ android-platform }}" --verbose
    sdkmanager --install "platform-tools" --verbose
    sdkmanager --install "ndk;{{ android-ndk }}" --verbose
    sdkmanager --install "system-images;android-{{ android-platform }};google_apis;arm64-v8a" --verbose

    cargo install cargo-bloat@0.12.1
    cargo install cargo-ndk@3.5.4

[private]
deps-ios:
    #!/bin/sh
    if [ "$GITHUB_ACTIONS" = "true" ]; then
        sudo xcode-select -switch /Applications/Xcode_{{ ios-xcode }}.app/Contents/Developer
    fi

    cargo install cargo-bloat@0.12.1

[private]
deps-web:
    cargo install cargo-bloat@0.12.1
    cargo install wasm-pack@0.13.1

# PACKAGE AND TEST

[doc("Bundle the native code in an AAR package")]
[working-directory("pkgs/aar")]
pkg-android:
    mkdir -p src/main
    cp -rf ../../native/target/bindings/android/* src/main/
    gradle build
    # FIXME: no "hello world" test yet - cargo ndk does not support darwin-aarch64 and native dylibs do not use the appropriate JNI symbols (prefixed with Java_namespace_methodname)
    ./gradlew publishToMavenLocal

[doc("Bundle the native code in a Swift package")]
[working-directory("pkgs/swift")]
pkg-ios: (pkg-ios-target "aarch64-apple-darwin") (pkg-ios-target "aarch64-apple-ios") (pkg-ios-target "aarch64-apple-ios-sim")
    swift build
    swift test

[doc("Open the iOS package in xcode")]
[working-directory("pkgs/swift")]
pkg-ios-open:
    open Package.swift

[private]
[working-directory("pkgs/swift")]
pkg-ios-target target:
    mkdir -p Sources/PdSdk
    cd Sources/PdSdk && \
        ln -fw ../../../../native/target/bindings/ios/{{ pkg-name }}.swift
    mkdir -p PdSdkFramework.xcframework/{{ target }}/headers/PdSdkFramework
    cd PdSdkFramework.xcframework/{{ target }} && \
        ln -fw ../../../../native/target/{{ target }}/release/{{ pkg-lib-static }}
    cd PdSdkFramework.xcframework/{{ target }}/headers/PdSdkFramework && \
        ln -fw ../../../../../../native/target/bindings/ios/{{ pkg-name }}FFI.modulemap module.modulemap && \
        ln -fw ../../../../../../native/target/bindings/ios/{{ pkg-name }}FFI.h

[doc("Bundle the native code in a NPM package")]
[working-directory("pkgs/npm")]
pkg-web:
    cp -rf ../../native/target/bindings/wasm/* .

[doc("Runs all native tests")]
[working-directory("native")]
test:
    cargo test
