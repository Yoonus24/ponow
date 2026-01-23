# Flutter specific rules
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }

# Required for Google ML Kit Text Recognition
-keep class com.google.mlkit.vision.text.** { *; }
-dontwarn com.google.mlkit.vision.text.**

# Optional: If using camera or image input
-keep class com.google.mlkit.vision.common.** { *; }
-dontwarn com.google.mlkit.vision.common.**

# Optional: Keep annotations (helps avoid missing metadata at runtime)
-keepattributes *Annotation*

# Required for Kotlin (used by Flutter and many plugins)
-keep class kotlin.Metadata { *; }

# Keep serialized classes used in JSON parsing
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}
-keep class com.google.gson.** { *; }
-dontwarn com.google.gson.**

# General keep rules for plugins (safe default)
-keep class com.google.** { *; }
-dontwarn com.google.**
-keep class androidx.** { *; }
-dontwarn androidx.**
-keep class org.jetbrains.** { *; }
-dontwarn org.jetbrains.**

# Prevent stripping of enums and reflective code
-keepclassmembers enum * { *; }
-keepclassmembers class * {
    public <init>(...);
}

# Optional: For debugging/logging tools
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
}
