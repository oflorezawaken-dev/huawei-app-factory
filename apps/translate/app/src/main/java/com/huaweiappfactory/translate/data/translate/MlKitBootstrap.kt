package com.huaweiappfactory.translate.data.translate

import android.content.ContentProvider
import android.content.ContentValues
import android.database.Cursor
import android.net.Uri
import android.util.Log
import com.huawei.agconnect.AGCRoutePolicy
import com.huawei.agconnect.AGConnectInstance
import com.huawei.agconnect.AGConnectOptionsBuilder
import com.huaweiappfactory.translate.BuildConfig

/**
 * Configures AGConnect, and through it ML Kit, before either of them starts.
 *
 * Both SDKs initialise from ContentProviders, which Android runs before
 * `Application.onCreate`, so configuring them in onCreate is too late: measured
 * on the phone, the log said `AGC Connect region is null` and
 * `AppMLKitGrsPolicy is null`, the SDK then resolved an endpoint from the SIM
 * country, and every model query came back HTTP 405.
 *
 * Doing it here, with a higher `initOrder`, means the app never ships
 * `agconnect-services.json` -- a credential file that factory rule 5 keeps out
 * of the repository and that would otherwise have to be injected from a secret
 * at build time. The two values that file would carry, the API key and the
 * route policy, are set explicitly instead.
 *
 * It provides no data. The ContentProvider is a lifecycle hook, nothing else.
 */
class MlKitBootstrap : ContentProvider() {

    override fun onCreate(): Boolean {
        val context = context ?: return false
        val apiKey = BuildConfig.ML_KIT_API_KEY
        if (apiKey.isBlank()) {
            Log.w(TAG, "ML_KIT_API_KEY is empty; language packs will not download.")
            return true
        }
        runCatching {
            val builder = AGConnectOptionsBuilder()
                .setApiKey(apiKey)
                // Where Huawei processes the model requests. This is a product
                // decision as much as a technical one: it has to match what the
                // privacy policy says.
                .setRoutePolicy(AGCRoutePolicy.GERMANY)
            AGConnectInstance.initialize(context, builder)
        }.onFailure { error ->
            Log.w(TAG, "AGConnect could not be initialised; ML Kit will not download models", error)
        }
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
