# ──────────────────────────────────────────────────────────────────────────────
# Supabase / PostgREST / Realtime (Kotlin serialization + Ktor/OkHttp)
# ──────────────────────────────────────────────────────────────────────────────
-keep class io.github.jan.supabase.** { *; }
-keep class io.ktor.** { *; }
-keep class kotlinx.serialization.** { *; }
-keepattributes *Annotation*, InnerClasses
-dontnote kotlinx.serialization.AnnotationsKt

# OkHttp (usado por baixo do ktor/supabase)
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }
-keep class okio.** { *; }

# Gson (se usado)
-keep class com.google.gson.** { *; }
-keepattributes Signature
-keepattributes EnclosingMethod

# Flutter (evitar remoção de entrypoints)
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }

# Supabase Auth / GoTrue
-keep class io.github.jan.supabase.gotrue.** { *; }

# Regras gerais recomendadas para projetos Flutter com R8
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# Ignorar classes ausentes do Play Store Core (referenciadas internamente pela Flutter Engine para Split/Deferred Components)
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**

