# Keep just_audio classes
-keep class com.google.android.exoplayer2.** { *; }
-keep class androidx.media3.** { *; }
-keep class com.ryanheise.just_audio.** { *; }

# Keep audio session classes
-keep class com.ryanheise.audio_session.** { *; }

# Keep OkHttp (used by ExoPlayer for HTTP streaming)
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }
-keep class okio.** { *; }

# Prevent stripping of native methods
-keepclasseswithmembernames class * {
    native <methods>;
}
