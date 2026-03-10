group = "com.example.mpv_audio_kit"
version = "1.0-SNAPSHOT"

buildscript {
    val kotlinVersion = "2.2.20"
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath("com.android.tools.build:gradle:8.7.2")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:2.0.21")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

plugins {
    id("com.android.library")
    id("kotlin-android")
}

android {
    namespace = "com.example.mpv_audio_kit"

    compileSdk = 36
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    sourceSets {
        getByName("main") {
            java.srcDirs("src/main/kotlin")
        }
        getByName("test") {
            java.srcDirs("src/test/kotlin")
        }
    }

    defaultConfig {
        minSdk = 24

        // ── libmpv NDK ──────────────────────────────────────────────────────
        // Richiede i sorgenti/prebuilts di libmpv nelle seguenti ABI.
        // Strategie supportate:
        //   1. Prefab: npm run build (mpv-android) e importa come AAR
        //   2. Prebuilt SO: copia libmpv.so in
        //      android/src/main/jniLibs/<abi>/libmpv.so
        //   3. mpv-android: usa il gradle script ufficiale
        //
        // Per ora il plugin carica libmpv.so a runtime via dart:ffi.
        // Se le .so sono presenti in jniLibs vengono packagizzate nell'APK.
        ndk {
            abiFilters += listOf("arm64-v8a", "x86_64")
        }

        // Link CMakeLists per il wrapper JNI/NDK
        externalNativeBuild {
            cmake {
                cppFlags("")
                arguments("-DANDROID_STL=c++_shared")
            }
        }
    }

    externalNativeBuild {
        cmake {
            path = file("src/main/cpp/CMakeLists.txt")
            version = "3.22.1"
        }
    }

    testOptions {
        unitTests {
            isIncludeAndroidResources = true
            all {
                it.useJUnitPlatform()

                it.outputs.upToDateWhen { false }

                it.testLogging {
                    events("passed", "skipped", "failed", "standardOut", "standardError")
                    showStandardStreams = true
                }
            }
        }
    }
}

dependencies {
    testImplementation("org.jetbrains.kotlin:kotlin-test")
    testImplementation("org.mockito:mockito-core:5.0.0")
}
