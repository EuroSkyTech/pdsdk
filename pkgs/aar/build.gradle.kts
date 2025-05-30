plugins {
    id("com.android.library") version "8.1.4"
    id("org.jetbrains.kotlin.android") version "1.9.10"
}

android {
    namespace = "com.bignextthing.pdsdk"
    compileSdk = 34

    defaultConfig { minSdk = 21 }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions { jvmTarget = "1.8" }
}

dependencies {
    implementation("androidx.annotation:annotation:1.7.1")
    implementation("net.java.dev.jna:jna:5.13.0@aar")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-core:1.6.4")

    testImplementation("junit:junit:4.13.2")
    testImplementation("org.jetbrains.kotlin:kotlin-test")
}
