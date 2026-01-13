package com.shaimaa.safechild

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.content.pm.PackageManager
import android.location.LocationManager
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationCompat
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey
import kotlinx.coroutines.*
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL

class LocationMonitorService : Service() {
    companion object {
        private const val TAG = "LocationMonitorService"
        private const val CHANNEL_ID = "LocationAlertChannel"
        private const val NOTIFICATION_ID = 1001
        private const val API_BASE_URL = "http://10.0.2.2:8000" // Default for Android emulator
        private const val GEO_ALERTS_ENDPOINT = "/api/geo-alerts/"
        private const val GEO_ZONES_ENDPOINT = "/api/geo-zones/"
        private const val NOTIFICATIONS_ENDPOINT = "/api/notifications/send-to-parent/"
    }

    private val scope = CoroutineScope(Dispatchers.IO + SupervisorJob())
    private lateinit var prefs: SharedPreferences
    private var locationTrackingJob: Job? = null
    private var lastKnownLocation: Pair<Double, Double>? = null

    override fun onCreate() {
        super.onCreate()

        // Initialize encrypted shared preferences
        try {
            val masterKey = MasterKey.Builder(this, MasterKey.DEFAULT_MASTER_KEY_ALIAS)
                .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
                .build()

            prefs = EncryptedSharedPreferences.create(
                this,
                "safechild_prefs",
                masterKey,
                EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
                EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
            )
            Log.d(TAG, "✅ EncryptedSharedPreferences initialized successfully")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error initializing encrypted preferences, falling back to regular preferences: ${e.message}")
            prefs = getSharedPreferences("safechild_prefs", MODE_PRIVATE)
        }

        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "📍 Starting Location Monitor Service")

        val childId = prefs.getString("child_id", "")
        if (childId.isNullOrEmpty()) {
            Log.e(TAG, "❌ No child ID found, cannot start location monitoring")
            stopSelf()
            return START_NOT_STICKY
        }

        startLocationMonitoring()
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Location Alerts",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Alerts for geographical restrictions"
            }

            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun startLocationMonitoring() {
        if (ActivityCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION) != PackageManager.PERMISSION_GRANTED) {
            Log.e(TAG, "❌ Location permission not granted")
            return
        }

        locationTrackingJob = scope.launch {
            while (isActive) {
                try {
                    checkCurrentLocation()
                    delay(30000) // Check every 30 seconds
                } catch (e: Exception) {
                    Log.e(TAG, "❌ Error in location monitoring: ${e.message}")
                    delay(60000) // Wait longer if there's an error
                }
            }
        }
    }

    private suspend fun checkCurrentLocation() {
        val currentLocation = getCurrentLocation()
        if (currentLocation != null) {
            if (lastKnownLocation != null) {
                val (prevLat, prevLng) = lastKnownLocation!!
                val (currLat, currLng) = currentLocation

                // Only process if location has changed significantly (more than 10 meters)
                if (calculateDistance(prevLat, prevLng, currLat, currLng) > 10) {
                    checkForZoneViolations(currentLocation.first, currentLocation.second)
                }
            }
            lastKnownLocation = currentLocation
        }
    }

    private fun getCurrentLocation(): Pair<Double, Double>? {
        try {
            val locationManager = getSystemService(Context.LOCATION_SERVICE) as LocationManager
            
            val providers = locationManager.allProviders
            for (provider in providers) {
                if (ActivityCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION) != PackageManager.PERMISSION_GRANTED) {
                    continue
                }
                
                val location = locationManager.getLastKnownLocation(provider)
                if (location != null) {
                    return Pair(location.latitude, location.longitude)
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error getting current location: ${e.message}")
        }
        
        return null
    }

    private suspend fun checkForZoneViolations(lat: Double, lng: Double) {
        val childId = prefs.getString("child_id", "") ?: ""
        if (childId.isEmpty()) return

        val zones = fetchGeoZonesForChild(childId)
        val currentLocation = Pair(lat, lng)

        for (zone in zones) {
            val zoneCenter = Pair(zone.latitude, zone.longitude)
            val distance = calculateDistance(
                currentLocation.first, 
                currentLocation.second, 
                zoneCenter.first, 
                zoneCenter.second
            )

            // Check if child is within the zone radius
            if (distance <= zone.radius) {
                // Check if it's a restricted zone
                if (zone.zoneType == "restricted") {
                    // Check if the time restriction is active
                    if (isTimeRestrictionActive(zone.startTime, zone.endTime, zone.isActive)) {
                        Log.d(TAG, "🚨 Child entered restricted zone: ${zone.name}")
                        
                        // Send alert to parent
                        sendGeoAlertToParent(zone, currentLocation)
                        
                        // Show local notification
                        showLocalNotification(zone.name)
                    }
                }
            }
        }
    }

    private suspend fun fetchGeoZonesForChild(childId: String): List<GeoZone> {
        return withContext(Dispatchers.IO) {
            try {
                val url = URL("$API_BASE_URL$GEO_ZONES_ENDPOINT?child=$childId")
                val connection = url.openConnection() as HttpURLConnection
                connection.requestMethod = "GET"
                connection.setRequestProperty("Content-Type", "application/json")
                connection.setRequestProperty("Accept", "application/json")

                val token = prefs.getString("auth_token", "") ?: ""
                if (token.isNotEmpty()) {
                    connection.setRequestProperty("Authorization", "Bearer $token")
                }

                val responseCode = connection.responseCode
                val responseBody = if (responseCode == 200) {
                    connection.inputStream.bufferedReader().readText()
                } else {
                    null
                }

                connection.disconnect()

                if (responseCode == 200 && responseBody != null) {
                    val zones = mutableListOf<GeoZone>()
                    val jsonArray = org.json.JSONArray(responseBody)

                    for (i in 0 until jsonArray.length()) {
                        val jsonObject = jsonArray.getJSONObject(i)
                        val zone = GeoZone(
                            id = jsonObject.optInt("id"),
                            child = jsonObject.optInt("child"),
                            name = jsonObject.optString("name"),
                            latitude = jsonObject.optDouble("latitude"),
                            longitude = jsonObject.optDouble("longitude"),
                            radius = jsonObject.optDouble("radius"),
                            zoneType = jsonObject.optString("zone_type"),
                            startTime = jsonObject.optString("start_time", "00:00"),
                            endTime = jsonObject.optString("end_time", "23:59"),
                            isActive = jsonObject.optBoolean("is_active", true),
                            createdAt = jsonObject.optString("created_at"),
                            updatedAt = jsonObject.optString("updated_at")
                        )
                        zones.add(zone)
                    }

                    Log.d(TAG, "✅ Fetched ${zones.size} geo zones for child $childId")
                    return@withContext zones
                } else {
                    Log.e(TAG, "❌ Failed to fetch geo zones. Response: $responseCode - $responseBody")
                    return@withContext emptyList()
                }
            } catch (e: Exception) {
                Log.e(TAG, "❌ Error fetching geo zones: ${e.message}")
                e.printStackTrace()
                return@withContext emptyList()
            }
        }
    }

    private suspend fun sendGeoAlertToParent(zone: GeoZone, currentLocation: Pair<Double, Double>) {
        scope.launch(Dispatchers.IO) {
            try {
                val parentId = prefs.getString("parent_id", "") ?: ""
                val childId = prefs.getString("child_id", "") ?: ""
                val childName = prefs.getString("child_name", "Child") ?: "Child"

                if (parentId.isEmpty() || childId.isEmpty()) {
                    Log.e(TAG, "❌ No parent ID or child ID found")
                    return@launch
                }

                val url = URL("$API_BASE_URL$NOTIFICATIONS_ENDPOINT")
                val connection = url.openConnection() as HttpURLConnection
                connection.requestMethod = "POST"
                connection.setRequestProperty("Content-Type", "application/json")
                connection.setRequestProperty("Accept", "application/json")
                connection.doOutput = true

                val token = prefs.getString("auth_token", "") ?: ""
                if (token.isNotEmpty()) {
                    connection.setRequestProperty("Authorization", "Bearer $token")
                }

                val description = "Child $childName entered restricted zone: ${zone.name} at ${currentLocation.first}, ${currentLocation.second}"

                val jsonBody = JSONObject().apply {
                    put("child_id", childId.toInt())
                    put("parent", parentId.toInt())
                    put("title", "Geographical Restriction Alert")
                    put("description", description)
                    put("category", "geo-restriction")
                }

                connection.outputStream.write(jsonBody.toString().toByteArray())

                val responseCode = connection.responseCode
                val responseMessage = try {
                    connection.inputStream?.bufferedReader()?.readText() ?: "Success"
                } catch (e: Exception) {
                    "Error reading response: ${e.message}"
                }

                Log.d(TAG, "📤 Geo alert sent, response: $responseCode - $responseMessage")

                connection.disconnect()

                // Also create a specific geo alert record
                createGeoAlertRecord(zone, currentLocation)

            } catch (e: Exception) {
                Log.e(TAG, "❌ Error sending geo alert: ${e.message}")
                e.printStackTrace()
            }
        }
    }

    private suspend fun createGeoAlertRecord(zone: GeoZone, currentLocation: Pair<Double, Double>) {
        withContext(Dispatchers.IO) {
            try {
                val url = URL("$API_BASE_URL$GEO_ALERTS_ENDPOINT")
                val connection = url.openConnection() as HttpURLConnection
                connection.requestMethod = "POST"
                connection.setRequestProperty("Content-Type", "application/json")
                connection.setRequestProperty("Accept", "application/json")
                connection.doOutput = true

                val token = prefs.getString("auth_token", "") ?: ""
                if (token.isNotEmpty()) {
                    connection.setRequestProperty("Authorization", "Bearer $token")
                }

                val jsonBody = JSONObject().apply {
                    put("child_id", zone.child)
                    put("zone_id", zone.id)
                    put("latitude", currentLocation.first)
                    put("longitude", currentLocation.second)
                    put("alert_type", "entry")
                    put("message", "Child entered restricted zone: ${zone.name}")
                }

                connection.outputStream.write(jsonBody.toString().toByteArray())

                val responseCode = connection.responseCode
                connection.disconnect()

                if (responseCode == 201) {
                    Log.d(TAG, "✅ Geo alert record created successfully")
                } else {
                    Log.e(TAG, "❌ Failed to create geo alert record: $responseCode")
                }
            } catch (e: Exception) {
                Log.e(TAG, "❌ Error creating geo alert record: ${e.message}")
            }
        }
    }

    private fun showLocalNotification(zoneName: String) {
        val childName = prefs.getString("child_name", "Child") ?: "Child"
        
        val notificationIntent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this, 0, notificationIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Geographical Restriction Alert")
            .setContentText("Child $childName entered restricted zone: $zoneName")
            .setSmallIcon(android.R.drawable.ic_dialog_alert)
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .build()

        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.notify(NOTIFICATION_ID, notification)
    }

    private fun calculateDistance(lat1: Double, lng1: Double, lat2: Double, lng2: Double): Double {
        val R = 6371e3 // Earth's radius in meters
        val φ1 = Math.toRadians(lat1)
        val φ2 = Math.toRadians(lat2)
        val Δφ = Math.toRadians(lat2 - lat1)
        val Δλ = Math.toRadians(lng2 - lng1)

        val a = (Math.sin(Δφ / 2) * Math.sin(Δφ / 2) +
                Math.cos(φ1) * Math.cos(φ2) *
                Math.sin(Δλ / 2) * Math.sin(Δλ / 2))
        val c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))

        return R * c // Distance in meters
    }

    private fun isTimeRestrictionActive(startTime: String, endTime: String, isActive: Boolean): Boolean {
        if (!isActive) return false

        try {
            val currentTime = java.util.Calendar.getInstance().time
            val sdf = java.text.SimpleDateFormat("HH:mm", java.util.Locale.getDefault())
            val currentTimeStr = sdf.format(currentTime)

            // Compare times - simplified for demonstration
            // In a production app, you'd want more sophisticated time comparison
            return true // For now, assume time restrictions are always active if enabled
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error checking time restriction: ${e.message}")
            return true // Default to active if there's an error
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        locationTrackingJob?.cancel()
        scope.cancel()
        Log.d(TAG, "📍 Location Monitor Service stopped")
    }
}

data class GeoZone(
    val id: Int,
    val child: Int,
    val name: String,
    val latitude: Double,
    val longitude: Double,
    val radius: Double,
    val zoneType: String, // "safe" or "restricted"
    val startTime: String,
    val endTime: String,
    val isActive: Boolean,
    val createdAt: String?,
    val updatedAt: String?
)