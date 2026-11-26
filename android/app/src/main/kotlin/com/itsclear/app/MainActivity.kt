package com.itsclear.app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.media.AudioAttributes
import android.provider.Settings
import android.location.Address
import android.location.Geocoder
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.Locale
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val geocoderExecutor: ExecutorService = Executors.newSingleThreadExecutor()

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                NOTIFICATION_CHANNEL_ID,
                "ItsClear Order & Offer Updates",
                NotificationManager.IMPORTANCE_HIGH,
            ).apply {
                description = "Real-time order, delivery, and offer updates"
                enableVibration(true)
                setSound(Settings.System.DEFAULT_NOTIFICATION_URI,
                    AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_NOTIFICATION).build())
            }
            getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, GEOCODING_CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method != "reverseGeocode") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val latitude = call.argument<Double>("latitude")
                val longitude = call.argument<Double>("longitude")
                if (latitude == null || longitude == null ||
                    latitude !in -90.0..90.0 || longitude !in -180.0..180.0) {
                    result.error("invalid_coordinates", "Valid coordinates are required.", null)
                    return@setMethodCallHandler
                }
                reverseGeocode(latitude, longitude, result)
            }
    }

    private fun reverseGeocode(latitude: Double, longitude: Double, result: MethodChannel.Result) {
        if (!Geocoder.isPresent()) {
            result.success(null)
            return
        }
        val geocoder = Geocoder(this, Locale("en", "IN"))
        if (Build.VERSION.SDK_INT >= 33) {
            geocoder.getFromLocation(latitude, longitude, 1, object : Geocoder.GeocodeListener {
                override fun onGeocode(addresses: MutableList<Address>) {
                    runOnUiThread { result.success(addresses.firstOrNull()?.let(::formatAddress)) }
                }

                override fun onError(errorMessage: String?) {
                    runOnUiThread { result.success(null) }
                }
            })
        } else {
            @Suppress("DEPRECATION")
            geocoderExecutor.execute {
                val address = try {
                    @Suppress("DEPRECATION")
                    geocoder.getFromLocation(latitude, longitude, 1)?.firstOrNull()
                } catch (_: Exception) {
                    null
                }
                runOnUiThread { result.success(address?.let(::formatAddress)) }
            }
        }
    }

    private fun formatAddress(address: Address): Map<String, String> = mapOf(
        "street" to listOfNotNull(address.subThoroughfare, address.thoroughfare, address.subLocality)
            .map(String::trim).filter(String::isNotEmpty).distinct().joinToString(", "),
        "city" to (address.locality ?: address.subAdminArea ?: ""),
        "state" to (address.adminArea ?: ""),
        "pincode" to (address.postalCode ?: ""),
    )

    override fun onDestroy() {
        geocoderExecutor.shutdown()
        super.onDestroy()
    }

    companion object {
        private const val GEOCODING_CHANNEL = "com.itsclear.app/geocoding"
        private const val NOTIFICATION_CHANNEL_ID = "itsclear_notifications"
    }
}
