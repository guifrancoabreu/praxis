# Kotlinx serialization keeps generated serializers reachable through reflection on the companion.
-keepattributes *Annotation*, InnerClasses
-dontnote kotlinx.serialization.**
-keepclassmembers class **$$serializer { *; }
-keepclasseswithmembers class * {
    kotlinx.serialization.KSerializer serializer(...);
}
-keep,includedescriptorclasses class br.praxis.android.**$$serializer { *; }
-keepclassmembers class br.praxis.android.** {
    *** Companion;
}

# Methods called from injected JavaScript must not be renamed.
-keepclassmembers class br.praxis.android.ui.reader.ReaderBridge {
    @android.webkit.JavascriptInterface <methods>;
}

# TelemetryDeck's Kotlin SDK.
-dontwarn com.telemetrydeck.**
