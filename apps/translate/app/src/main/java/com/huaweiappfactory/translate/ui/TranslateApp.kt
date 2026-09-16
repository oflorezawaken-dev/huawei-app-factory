package com.huaweiappfactory.translate.ui

import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.ui.platform.LocalContext
import androidx.lifecycle.viewmodel.compose.viewModel
import com.huaweiappfactory.translate.TranslateApplication
import com.huaweiappfactory.translate.ads.LocalAdManager
import com.huaweiappfactory.translate.ui.screens.TranslateScreen
import com.huaweiappfactory.translate.ui.screens.TranslateViewModel
import com.huaweiappfactory.translate.ui.theme.TranslateTheme

@Composable
fun TranslateApp() {
    val app = LocalContext.current.applicationContext as TranslateApplication
    TranslateTheme {
        CompositionLocalProvider(LocalAdManager provides app.container.adManager) {
            val viewModel: TranslateViewModel = viewModel(
                factory = TranslateViewModel.factory(app.container.translationEngine)
            )
            TranslateScreen(viewModel)
        }
    }
}
