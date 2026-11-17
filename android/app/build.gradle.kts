import java.util.Properties
import java.io.FileInputStream

plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.compose)
    alias(libs.plugins.kotlin.serialization)
}

// Upload key material stays outside the repository; without it the release build still assembles
// (unsigned), which is what CI does.
val keystoreProperties = Properties().apply {
    val file = rootProject.file("keystore.properties")
    if (file.isFile) FileInputStream(file).use { load(it) }
}

android {
    namespace = "br.praxis.android"
    compileSdk = 37

    defaultConfig {
        applicationId = "br.praxis.android"
        minSdk = 26
        targetSdk = 36
        versionCode = 1
        versionName = "1.0.0"
        resourceConfigurations += listOf("pt", "pt-rBR", "en", "es")
        val feedbackUrl = providers.gradleProperty("feedbackUrl").orElse("https://praxis-feedback.guifrancoabr.workers.dev").get()
        buildConfigField("String", "FEEDBACK_URL", "\"${feedbackUrl.replace("\\", "\\\\").replace("\"", "\\\"")}\"")
    }

    // Catalogs and reader assets are shared with the iOS app; both are read straight from the
    // repository instead of being copied into the module. The release is Portuguese-only, so only
    // that snapshot is packaged; adding a language means adding it to this filter.
    sourceSets["main"].assets.srcDirs(
        "src/main/assets",
        "../../shared/catalog",
        "../../shared/reader",
    )

    signingConfigs {
        if (keystoreProperties.getProperty("storeFile") != null) {
            create("upload") {
                storeFile = rootProject.file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
            signingConfig = signingConfigs.findByName("upload")
        }
        debug {
            applicationIdSuffix = ".debug"
        }
    }

    bundle {
        language.enableSplit = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    buildFeatures {
        compose = true
        buildConfig = true
    }

    packaging {
        resources.excludes += "/META-INF/{AL2.0,LGPL2.1}"
    }

    // The release ships Portuguese only; the other snapshots stay in the repository for later.
    androidResources {
        ignoreAssetsPattern = "catalog-en.json:catalog-es.json"
    }
}

dependencies {
    implementation(libs.androidx.core.ktx)
    implementation(libs.androidx.activity.compose)
    implementation(libs.androidx.lifecycle.runtime.compose)
    implementation(libs.androidx.lifecycle.viewmodel.compose)
    implementation(libs.androidx.navigation.compose)
    implementation(libs.androidx.datastore.preferences)
    implementation(libs.androidx.webkit)

    implementation(platform(libs.compose.bom))
    implementation(libs.compose.ui)
    implementation(libs.compose.ui.graphics)
    implementation(libs.compose.foundation)
    implementation(libs.compose.material3)
    implementation(libs.compose.material.icons)
    implementation(libs.compose.material.icons.extended)
    implementation(libs.compose.ui.tooling.preview)
    debugImplementation(libs.compose.ui.tooling)

    implementation(libs.kotlinx.serialization.json)
    implementation(libs.kotlinx.coroutines.android)
    implementation(libs.okhttp)
    implementation(libs.jsoup)
    implementation(libs.coil.compose)
    implementation(libs.coil.network.okhttp)
    implementation(libs.telemetrydeck)

    testImplementation(libs.junit)
    testImplementation(libs.kotlin.test)
}
