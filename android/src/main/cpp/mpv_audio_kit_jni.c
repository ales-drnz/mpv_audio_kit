/*
 * mpv_audio_kit_jni.c
 *
 * Thin JNI/NDK wrapper stub.
 * La logica principale è implementata in Dart via dart:ffi che carica
 * direttamente libmpv.so. Questo file esiste per soddisfare il sistema
 * di build Flutter Android (ffiPlugin:true).
 *
 * Su Android, dart:ffi carica libmpv.so tramite:
 *   DynamicLibrary.open('libmpv.so')
 * che funziona perché la .so è packagizzata nell'APK in jniLibs/<abi>/.
 */

#include <jni.h>
#include <android/log.h>

#define LOG_TAG "mpv_audio_kit"
#define LOGD(...) __android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, __VA_ARGS__)

JNIEXPORT jint JNICALL JNI_OnLoad(JavaVM *vm, void *reserved) {
    LOGD("mpv_audio_kit JNI loaded");
    return JNI_VERSION_1_6;
}
