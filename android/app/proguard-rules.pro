# ProGuard rules for printing package and lStar attribute
-keep class * extends android.content.res.Resources
-keep class android.content.res.Resources$Theme { *; }
-keep class android.util.AttributeSet { *; }
-keep class android.util.TypedValue { *; }

# Keep all printing related classes
-keep class net.nfet.flutter.printing.** { *; }

# Keep all Android material components
-keep class com.google.android.material.** { *; }

# Disable attribute optimizations that may cause issues with lStar
-optimizations !field/removal/writeonly,!field/marking/private,!class/merging/*,!code/allocation/variable

# Keep all attributes
-keepattributes *
