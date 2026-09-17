// Huawei publishes the AGConnect plugin as a classpath artifact with no plugin
// marker, so it cannot come through the plugins {} block like the others.
buildscript {
  repositories {
    google()
    mavenCentral()
    maven { url = uri("https://developer.huawei.com/repo/") }
  }
  dependencies {
    classpath(libs.huawei.agconnect.plugin)
  }
}

// Top-level build file where you can add configuration options common to all sub-projects/modules.
plugins {
  alias(libs.plugins.android.application) apply false
  alias(libs.plugins.kotlin.compose) apply false
  alias(libs.plugins.google.devtools.ksp) apply false
}
