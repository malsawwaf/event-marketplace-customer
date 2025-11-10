package com.event.marketplace.customer

import android.graphics.Color
import android.util.Log
import android.os.Bundle
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import com.paymob.paymob_sdk.PaymobSdk
import com.paymob.paymob_sdk.ui.PaymobSdkListener

class MainActivity: FlutterActivity(), MethodCallHandler, PaymobSdkListener {
    private val CHANNEL = "paymob_sdk_flutter"
    private var sdkResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        if (call.method == "payWithPaymob") {
            sdkResult = result
            val arguments = call.arguments as? Map<String, Any>

            if (arguments != null) {
                callNativeSDK(arguments)
            } else {
                result.error("INVALID_ARGS", "Arguments cannot be null", null)
            }
        } else {
            result.notImplemented()
        }
    }

    private fun callNativeSDK(arguments: Map<String, Any>) {
        try {
            val publicKey = arguments["publicKey"] as? String
            val clientSecret = arguments["clientSecret"] as? String

            if (publicKey == null || clientSecret == null) {
                sdkResult?.error("MISSING_PARAMS", "Public key and client secret are required", null)
                return
            }

            Log.d("PaymobSDK", "Public Key: $publicKey")
            Log.d("PaymobSDK", "Client Secret: ${clientSecret.take(20)}...")

            // Build Paymob SDK
            val paymobSdkBuilder = PaymobSdk.Builder(
                context = this@MainActivity,
                clientSecret = clientSecret,
                publicKey = publicKey,
                paymobSdkListener = this
            )

            // Apply customizations if provided
            arguments["buttonBackgroundColor"]?.let {
                val colorInt = (it as Number).toInt()
                paymobSdkBuilder.setButtonBackgroundColor(colorInt)
            }

            arguments["buttonTextColor"]?.let {
                val colorInt = (it as Number).toInt()
                paymobSdkBuilder.setButtonTextColor(colorInt)
            }

            arguments["saveCardDefault"]?.let { value: Any ->
                // Note: Method name may vary by SDK version
                // paymobSdkBuilder.isSavedCardCheckBoxCheckedByDefault(value as Boolean)
            }

            arguments["showSaveCard"]?.let { value: Any ->
                // Note: Method name may vary by SDK version
                // paymobSdkBuilder.isAbleToSaveCard(value as Boolean)
            }

            val paymobSdk = paymobSdkBuilder.build()

            // Start the SDK
            paymobSdk.start()

        } catch (e: Exception) {
            Log.e("PaymobSDK", "Error starting SDK: ${e.message}")
            sdkResult?.error("SDK_ERROR", e.message, null)
        }
    }

    // PaymobSdkListener callbacks
    override fun onSuccess(payResponse: HashMap<String, String?>) {
        Log.d("PaymobSDK", "Transaction Successful: $payResponse")
        sdkResult?.success("Successfull")
        sdkResult = null
    }

    override fun onFailure() {
        Log.d("PaymobSDK", "Transaction Rejected")
        sdkResult?.success("Rejected")
        sdkResult = null
    }

    override fun onPending() {
        Log.d("PaymobSDK", "Transaction Pending")
        sdkResult?.success("Pending")
        sdkResult = null
    }
}
