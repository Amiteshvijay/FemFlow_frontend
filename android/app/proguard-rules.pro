# Flutter ProGuard Rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class com.google.firebase.** { *; }
-keep class androidx.lifecycle.DefaultLifecycleObserver { *; }

# Razorpay ProGuard Rules (if needed, but usually plugin handles it)
-keep class com.razorpay.** {*;}
-dontwarn com.razorpay.**

# Google Fonts
-keep class com.google.fonts.** { *; }
