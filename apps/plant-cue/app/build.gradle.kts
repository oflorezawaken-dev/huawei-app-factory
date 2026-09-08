plugins {
  alias(libs.plugins.android.application)
  alias(libs.plugins.kotlin.compose)
  alias(libs.plugins.google.devtools.ksp)
}

val releaseKeystorePath = System.getenv("RELEASE_KEYSTORE_PATH")
val releaseKeystorePassword = System.getenv("RELEASE_KEYSTORE_PASSWORD")
val releaseKeyAlias = System.getenv("RELEASE_KEY_ALIAS")
val releaseKeyPassword = System.getenv("RELEASE_KEY_PASSWORD")
val hasReleaseSigning = listOf(
  releaseKeystorePath,
  releaseKeystorePassword,
  releaseKeyAlias,
  releaseKeyPassword
).all { !it.isNullOrBlank() }

// Huawei Petal Ads unit IDs come from the environment (CI exports them from
// factory/apps.json) or gradle.properties; never hard-coded. When absent we fall
// back to Huawei's documented TEST ad units so debug builds show test ads.
fun adId(envName: String, testId: String): Pair<String, Boolean> {
  val fromEnv = System.getenv(envName)
  val fromProps = project.findProperty(envName) as String?
  val real = listOf(fromEnv, fromProps).firstOrNull { !it.isNullOrBlank() }
  return if (real != null) real to false else testId to true
}
val (petalBannerId, bannerIsTest) = adId("PETAL_BANNER_AD_ID", "testw6vs28auh3")
val (petalInterstitialId, interstitialIsTest) = adId("PETAL_INTERSTITIAL_AD_ID", "teste9ih9j0rc3")
val petalUsingTestIds = bannerIsTest || interstitialIsTest
if (petalUsingTestIds && hasReleaseSigning) {
  logger.warn("WARNING: signed release is being built with Huawei TEST ad unit IDs. Set PETAL_BANNER_AD_ID / PETAL_INTERSTITIAL_AD_ID before publishing.")
}

android {
  namespace = "com.huaweiappfactory.plantcue"
  compileSdk { version = release(36) { minorApiLevel = 1 } }

  defaultConfig {
    applicationId = "com.huaweiappfactory.plantcue"
    minSdk = 26
    targetSdk = 36
    versionCode = 2
    versionName = "1.0.1"

    buildConfigField("String", "PETAL_BANNER_AD_ID", "\"$petalBannerId\"")
    buildConfigField("String", "PETAL_INTERSTITIAL_AD_ID", "\"$petalInterstitialId\"")
    buildConfigField("boolean", "PETAL_ADS_USING_TEST_IDS", "$petalUsingTestIds")

    testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
  }

  signingConfigs {
    if (hasReleaseSigning) {
      create("release") {
        storeFile = file(requireNotNull(releaseKeystorePath))
        storePassword = requireNotNull(releaseKeystorePassword)
        keyAlias = requireNotNull(releaseKeyAlias)
        keyPassword = requireNotNull(releaseKeyPassword)
      }
    }
  }

  buildTypes {
    release {
      isCrunchPngs = false
      isMinifyEnabled = false
      proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
      if (hasReleaseSigning) {
        signingConfig = signingConfigs.getByName("release")
      }
    }
  }
  compileOptions {
    sourceCompatibility = JavaVersion.VERSION_11
    targetCompatibility = JavaVersion.VERSION_11
  }
  buildFeatures {
    compose = true
    buildConfig = true
  }
  dependenciesInfo {
    includeInApk = false
    includeInBundle = false
  }
}

dependencies {
  implementation(platform(libs.androidx.compose.bom))
  implementation(libs.androidx.activity.compose)
  implementation(libs.androidx.compose.material.icons.core)
  implementation(libs.androidx.compose.material.icons.extended)
  implementation(libs.androidx.compose.material3)
  implementation(libs.androidx.compose.ui)
  implementation(libs.androidx.compose.ui.graphics)
  implementation(libs.androidx.compose.ui.tooling.preview)
  implementation(libs.androidx.core.ktx)
  implementation(libs.androidx.lifecycle.runtime.compose)
  implementation(libs.androidx.lifecycle.runtime.ktx)
  implementation(libs.androidx.lifecycle.viewmodel.compose)
  implementation(libs.androidx.navigation.compose)
  implementation(libs.androidx.room.ktx)
  implementation(libs.androidx.room.runtime)
  implementation(libs.androidx.work.runtime.ktx)
  implementation(libs.coil.compose)
  implementation(libs.kotlinx.coroutines.android)
  implementation(libs.kotlinx.coroutines.core)
  implementation(libs.huawei.ads.lite)
  testImplementation(libs.junit)
  testImplementation(libs.kotlinx.coroutines.test)
  androidTestImplementation(platform(libs.androidx.compose.bom))
  androidTestImplementation(libs.androidx.compose.ui.test.junit4)
  androidTestImplementation(libs.androidx.espresso.core)
  androidTestImplementation(libs.androidx.junit)
  androidTestImplementation(libs.androidx.runner)
  debugImplementation(libs.androidx.compose.ui.test.manifest)
  debugImplementation(libs.androidx.compose.ui.tooling)
  "ksp"(libs.androidx.room.compiler)
}
