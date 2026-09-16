package com.huaweiappfactory.translate.data.translate

import android.content.ContentProvider
import android.content.ContentValues
import android.database.Cursor
import android.net.Uri
import android.util.Log
import com.huawei.agconnect.AGConnectInstance
import com.huawei.agconnect.config.AGConnectServicesConfig
import com.huawei.hms.mlsdk.common.MLApplication

/**
 * Hands ML Kit its API key before ML Kit starts.
 *
 * ML Kit initialises from `MLInitializerProvider`, a ContentProvider, and
 * Android runs providers before `Application.onCreate`; configuring it in
 * onCreate is too late, and the app then fails at the first model download
 * with "please set your app apiKey". Measured on the phone.
 *
 * The key is read from the AGConnect config rather than from a BuildConfig
 * constant, so there is one credential to manage instead of two:
 * `agconnect-services.json` is injected by CI from a secret, never enters git
 * (factory rule 5), and routing comes from the same file -- without it the SDK
 * resolves an endpoint from the SIM country and every model query returns 405.
 *
 * It provides no data. The ContentProvider is a lifecycle hook, nothing else.
 */
class MlKitBootstrap : ContentProvider() {

    override fun onCreate(): Boolean {
        val context = context ?: return false
        val apiKey = runCatching {
            AGConnectServicesConfig.fromContext(context).getString("client/api_key")
        }.getOrNull()
        if (apiKey.isNullOrBlank()) {
            Log.w(TAG, "No AGConnect api_key: agconnect-services.json is missing from this build.")
            return true
        }
        // MLApplication.getInstance() dereferences the AGConnect instance, and
        // AGConnect's own provider has not run yet at this initOrder: without this
        // line the app crashes on start with a null AGConnectInstance. Measured.
        runCatching { AGConnectInstance.initialize(context) }
        MLApplication.getInstance().apiKey = apiKey
        return true
    }

    override fun query(
        uri: Uri,
        projection: Array<out String>?,
        selection: String?,
        selectionArgs: Array<out String>?,
        sortOrder: String?
    ): Cursor? = null

    override fun getType(uri: Uri): String? = null

    override fun insert(uri: Uri, values: ContentValues?): Uri? = null

    override fun delete(uri: Uri, selection: String?, selectionArgs: Array<out String>?): Int = 0

    override fun update(
        uri: Uri,
        values: ContentValues?,
        selection: String?,
        selectionArgs: Array<out String>?
    ): Int = 0

    private companion object {
        const val TAG = "MlKitBootstrap"
    }
}
