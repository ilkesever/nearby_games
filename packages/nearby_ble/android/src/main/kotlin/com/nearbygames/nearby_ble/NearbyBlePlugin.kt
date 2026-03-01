package com.nearbygames.nearby_ble

import android.Manifest
import android.app.Activity
import android.bluetooth.*
import android.bluetooth.le.*
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.ParcelUuid
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import java.nio.charset.StandardCharsets
import java.text.SimpleDateFormat
import java.util.*

/**
 * Flutter plugin for BLE-based nearby communication on Android.
 *
 * Uses Android BLE APIs to implement both Central (scanner/joiner) and
 * Peripheral (advertiser/host) roles for cross-platform P2P gaming.
 */
class NearbyBlePlugin : FlutterPlugin, MethodCallHandler, EventChannel.StreamHandler,
    ActivityAware, PluginRegistry.RequestPermissionsResultListener {

    companion object {
        private const val TAG = "NearbyBLE"
        private const val PERMISSION_REQUEST_CODE = 9001

        // Must match iOS UUIDs exactly for cross-platform compatibility
        val SERVICE_UUID: UUID = UUID.fromString("A1B2C3D4-E5F6-7890-ABCD-EF1234567890")
        val MESSAGE_CHAR_UUID: UUID = UUID.fromString("A1B2C3D4-E5F6-7890-ABCD-EF1234567891")
        val PLAYER_INFO_CHAR_UUID: UUID = UUID.fromString("A1B2C3D4-E5F6-7890-ABCD-EF1234567892")

        // Client Characteristic Configuration Descriptor UUID (standard)
        val CCCD_UUID: UUID = UUID.fromString("00002902-0000-1000-8000-00805f9b34fb")
    }

    // Flutter channels
    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var eventSink: EventChannel.EventSink? = null

    // Android context
    private var context: Context? = null
    private var activity: Activity? = null

    // Bluetooth
    private var bluetoothManager: BluetoothManager? = null
    private var bluetoothAdapter: BluetoothAdapter? = null

    // Central (scanner/joiner)
    private var bluetoothLeScanner: BluetoothLeScanner? = null
    private var discoveredDevices: MutableMap<String, BluetoothDevice> = mutableMapOf()
    private var connectedGatt: BluetoothGatt? = null
    private var messageCharacteristic: BluetoothGattCharacteristic? = null

    // Peripheral (advertiser/host)
    private var bluetoothLeAdvertiser: BluetoothLeAdvertiser? = null
    private var gattServer: BluetoothGattServer? = null
    private var connectedCentralDevice: BluetoothDevice? = null
    private var subscribedDevices: MutableList<BluetoothDevice> = mutableListOf()

    // State
    private var localPlayerName: String = "Player"
    private var gameType: String = ""
    private var scanningGameType: String = ""
    private var sessionId: String = ""
    private var isHosting = false
    private var isScanning = false

    // Pending results
    private var pendingConnectResult: Result? = null
    private var pendingPermissionResult: Result? = null

    private val mainHandler = Handler(Looper.getMainLooper())

    // ========================================================================
    // FlutterPlugin lifecycle
    // ========================================================================

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext

        methodChannel = MethodChannel(binding.binaryMessenger, "com.nearbygames/nearby_ble")
        methodChannel.setMethodCallHandler(this)

        eventChannel = EventChannel(binding.binaryMessenger, "com.nearbygames/nearby_ble/events")
        eventChannel.setStreamHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        context = null
    }

    // ========================================================================
    // ActivityAware
    // ========================================================================

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() { activity = null }
    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }
    override fun onDetachedFromActivity() { activity = null }

    // ========================================================================
    // MethodCallHandler
    // ========================================================================

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "initialize" -> initialize(result)
            "isAvailable" -> isAvailable(result)
            "requestPermissions" -> requestPermissions(result)
            "startHosting" -> startHosting(call, result)
            "stopHosting" -> stopHosting(result)
            "startScanning" -> startScanning(call, result)
            "stopScanning" -> stopScanning(result)
            "connect" -> connect(call, result)
            "disconnect" -> disconnect(result)
            "sendMessage" -> sendMessage(call, result)
            else -> result.notImplemented()
        }
    }

    // ========================================================================
    // EventChannel.StreamHandler
    // ========================================================================

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    // ========================================================================
    // Initialize
    // ========================================================================

    private fun initialize(result: Result) {
        val ctx = context ?: run {
            result.error("BLE_UNAVAILABLE", "Context not available", null)
            return
        }

        bluetoothManager = ctx.getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
        bluetoothAdapter = bluetoothManager?.adapter

        if (bluetoothAdapter == null) {
            result.error("BLE_UNAVAILABLE", "Bluetooth is not available on this device", null)
            return
        }

        result.success(null)
    }

    private fun isAvailable(result: Result) {
        val adapter = bluetoothAdapter
        result.success(adapter != null && adapter.isEnabled)
    }

    private fun requestPermissions(result: Result) {
        val act = activity ?: run {
            result.error("BLE_UNAVAILABLE", "Activity not available", null)
            return
        }

        val permissions = mutableListOf<String>()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            // Android 12+
            permissions.add(Manifest.permission.BLUETOOTH_SCAN)
            permissions.add(Manifest.permission.BLUETOOTH_ADVERTISE)
            permissions.add(Manifest.permission.BLUETOOTH_CONNECT)
        }
        permissions.add(Manifest.permission.ACCESS_FINE_LOCATION)

        val missing = permissions.filter {
            ContextCompat.checkSelfPermission(act, it) != PackageManager.PERMISSION_GRANTED
        }

        if (missing.isEmpty()) {
            result.success(true)
            return
        }

        pendingPermissionResult = result
        ActivityCompat.requestPermissions(act, missing.toTypedArray(), PERMISSION_REQUEST_CODE)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int, permissions: Array<out String>, grantResults: IntArray
    ): Boolean {
        if (requestCode != PERMISSION_REQUEST_CODE) return false

        val allGranted = grantResults.all { it == PackageManager.PERMISSION_GRANTED }
        pendingPermissionResult?.success(allGranted)
        pendingPermissionResult = null
        return true
    }

    // ========================================================================
    // Host Mode (Peripheral / Advertiser)
    // ========================================================================

    private fun startHosting(call: MethodCall, result: Result) {
        val adapter = bluetoothAdapter ?: run {
            result.error("BLE_DISABLED", "Bluetooth not available", null)
            return
        }

        if (!adapter.isEnabled) {
            result.error("BLE_DISABLED", "Bluetooth is not enabled", null)
            return
        }

        gameType = call.argument<String>("gameType") ?: "unknown"
        localPlayerName = call.argument<String>("playerName") ?: "Player"
        sessionId = UUID.randomUUID().toString()

        // Set up GATT server
        gattServer = bluetoothManager?.openGattServer(context, gattServerCallback)

        val service = BluetoothGattService(SERVICE_UUID, BluetoothGattService.SERVICE_TYPE_PRIMARY)

        val messageCh = BluetoothGattCharacteristic(
            MESSAGE_CHAR_UUID,
            BluetoothGattCharacteristic.PROPERTY_WRITE or
                    BluetoothGattCharacteristic.PROPERTY_NOTIFY or
                    BluetoothGattCharacteristic.PROPERTY_WRITE_NO_RESPONSE,
            BluetoothGattCharacteristic.PERMISSION_WRITE or
                    BluetoothGattCharacteristic.PERMISSION_READ
        )
        // Add CCCD for notifications
        val cccd = BluetoothGattDescriptor(
            CCCD_UUID,
            BluetoothGattDescriptor.PERMISSION_READ or BluetoothGattDescriptor.PERMISSION_WRITE
        )
        messageCh.addDescriptor(cccd)

        val playerInfoCh = BluetoothGattCharacteristic(
            PLAYER_INFO_CHAR_UUID,
            BluetoothGattCharacteristic.PROPERTY_READ,
            BluetoothGattCharacteristic.PERMISSION_READ
        )
        playerInfoCh.value = localPlayerName.toByteArray(StandardCharsets.UTF_8)

        service.addCharacteristic(messageCh)
        service.addCharacteristic(playerInfoCh)

        gattServer?.addService(service)

        // Start advertising
        bluetoothLeAdvertiser = adapter.bluetoothLeAdvertiser
        val settings = AdvertiseSettings.Builder()
            .setAdvertiseMode(AdvertiseSettings.ADVERTISE_MODE_LOW_LATENCY)
            .setTxPowerLevel(AdvertiseSettings.ADVERTISE_TX_POWER_HIGH)
            .setConnectable(true)
            .build()

        val data = AdvertiseData.Builder()
            .addServiceUuid(ParcelUuid(SERVICE_UUID))
            .setIncludeDeviceName(false)
            .build()

        val scanResponse = AdvertiseData.Builder()
            .addServiceData(
                ParcelUuid(SERVICE_UUID),
                "$gameType|$localPlayerName".toByteArray(StandardCharsets.UTF_8)
            )
            .build()

        bluetoothLeAdvertiser?.startAdvertising(settings, data, scanResponse, advertiseCallback)
        isHosting = true

        result.success(null)
    }

    private fun stopHosting(result: Result) {
        bluetoothLeAdvertiser?.stopAdvertising(advertiseCallback)
        gattServer?.close()
        gattServer = null
        isHosting = false
        subscribedDevices.clear()
        connectedCentralDevice = null
        result.success(null)
    }

    private val advertiseCallback = object : AdvertiseCallback() {
        override fun onStartSuccess(settingsInEffect: AdvertiseSettings?) {
            Log.d(TAG, "Advertising started successfully")
        }

        override fun onStartFailure(errorCode: Int) {
            Log.e(TAG, "Advertising failed with error: $errorCode")
            sendEvent(mapOf(
                "event" to "error",
                "code" to "BLE_UNAVAILABLE",
                "message" to "Failed to start advertising (error $errorCode)"
            ))
        }
    }

    private val gattServerCallback = object : BluetoothGattServerCallback() {
        override fun onConnectionStateChange(device: BluetoothDevice, status: Int, newState: Int) {
            if (newState == BluetoothProfile.STATE_CONNECTED) {
                connectedCentralDevice = device
                Log.d(TAG, "Central connected: ${device.address}")
            } else if (newState == BluetoothProfile.STATE_DISCONNECTED) {
                subscribedDevices.removeAll { it.address == device.address }
                if (subscribedDevices.isEmpty()) {
                    connectedCentralDevice = null
                    sendEvent(mapOf("event" to "disconnected"))
                }
            }
        }

        override fun onCharacteristicReadRequest(
            device: BluetoothDevice, requestId: Int, offset: Int,
            characteristic: BluetoothGattCharacteristic
        ) {
            when (characteristic.uuid) {
                PLAYER_INFO_CHAR_UUID -> {
                    val data = localPlayerName.toByteArray(StandardCharsets.UTF_8)
                    gattServer?.sendResponse(device, requestId, BluetoothGatt.GATT_SUCCESS, offset,
                        data.copyOfRange(offset, data.size))
                }
                else -> {
                    gattServer?.sendResponse(device, requestId, BluetoothGatt.GATT_REQUEST_NOT_SUPPORTED, 0, null)
                }
            }
        }

        override fun onCharacteristicWriteRequest(
            device: BluetoothDevice, requestId: Int,
            characteristic: BluetoothGattCharacteristic,
            preparedWrite: Boolean, responseNeeded: Boolean,
            offset: Int, value: ByteArray?
        ) {
            if (characteristic.uuid == MESSAGE_CHAR_UUID && value != null) {
                val jsonString = String(value, StandardCharsets.UTF_8)
                sendEvent(mapOf(
                    "event" to "message",
                    "data" to jsonString
                ))

                if (responseNeeded) {
                    gattServer?.sendResponse(device, requestId, BluetoothGatt.GATT_SUCCESS, 0, null)
                }
            } else if (responseNeeded) {
                gattServer?.sendResponse(device, requestId, BluetoothGatt.GATT_REQUEST_NOT_SUPPORTED, 0, null)
            }
        }

        override fun onDescriptorWriteRequest(
            device: BluetoothDevice, requestId: Int,
            descriptor: BluetoothGattDescriptor,
            preparedWrite: Boolean, responseNeeded: Boolean,
            offset: Int, value: ByteArray?
        ) {
            if (descriptor.uuid == CCCD_UUID) {
                if (value?.contentEquals(BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE) == true) {
                    // Client subscribed to notifications
                    if (!subscribedDevices.any { it.address == device.address }) {
                        subscribedDevices.add(device)
                    }

                    val connection = mapOf(
                        "sessionId" to sessionId,
                        "remoteDevice" to mapOf(
                            "id" to device.address,
                            "name" to "Opponent",
                            "gameType" to gameType,
                            "metadata" to emptyMap<String, String>()
                        ),
                        "localRole" to "host",
                        "connectedAt" to currentIsoTimestamp()
                    )
                    sendEvent(mapOf("event" to "connected", "connection" to connection))
                } else {
                    subscribedDevices.removeAll { it.address == device.address }
                    if (subscribedDevices.isEmpty()) {
                        sendEvent(mapOf("event" to "disconnected"))
                    }
                }

                if (responseNeeded) {
                    gattServer?.sendResponse(device, requestId, BluetoothGatt.GATT_SUCCESS, 0, null)
                }
            }
        }

        override fun onDescriptorReadRequest(
            device: BluetoothDevice, requestId: Int, offset: Int,
            descriptor: BluetoothGattDescriptor
        ) {
            if (descriptor.uuid == CCCD_UUID) {
                val value = if (subscribedDevices.any { it.address == device.address }) {
                    BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE
                } else {
                    BluetoothGattDescriptor.DISABLE_NOTIFICATION_VALUE
                }
                gattServer?.sendResponse(device, requestId, BluetoothGatt.GATT_SUCCESS, 0, value)
            }
        }
    }

    // ========================================================================
    // Join Mode (Central / Scanner)
    // ========================================================================

    private fun startScanning(call: MethodCall, result: Result) {
        val adapter = bluetoothAdapter ?: run {
            result.error("BLE_DISABLED", "Bluetooth not available", null)
            return
        }

        if (!adapter.isEnabled) {
            result.error("BLE_DISABLED", "Bluetooth is not enabled", null)
            return
        }

        scanningGameType = call.argument<String>("gameType") ?: ""
        discoveredDevices.clear()

        bluetoothLeScanner = adapter.bluetoothLeScanner

        val filters = listOf(
            ScanFilter.Builder()
                .setServiceUuid(ParcelUuid(SERVICE_UUID))
                .build()
        )

        val settings = ScanSettings.Builder()
            .setScanMode(ScanSettings.SCAN_MODE_LOW_LATENCY)
            .build()

        bluetoothLeScanner?.startScan(filters, settings, scanCallback)
        isScanning = true

        result.success(null)
    }

    private fun stopScanning(result: Result) {
        bluetoothLeScanner?.stopScan(scanCallback)
        isScanning = false
        result.success(null)
    }

    private val scanCallback = object : ScanCallback() {
        override fun onScanResult(callbackType: Int, scanResult: ScanResult) {
            val device = scanResult.device
            val id = device.address
            discoveredDevices[id] = device

            // Parse service data for game type and player name
            val serviceData = scanResult.scanRecord?.getServiceData(ParcelUuid(SERVICE_UUID))
            var advGameType = "unknown"
            var playerName = "Unknown Player"

            if (serviceData != null) {
                val dataStr = String(serviceData, StandardCharsets.UTF_8)
                val parts = dataStr.split("|", limit = 2)
                if (parts.isNotEmpty()) advGameType = parts[0]
                if (parts.size > 1) playerName = parts[1]
            }

            // Filter by game type
            if (scanningGameType.isNotEmpty() && advGameType != scanningGameType) {
                return
            }

            sendEvent(mapOf(
                "event" to "deviceFound",
                "device" to mapOf(
                    "id" to id,
                    "name" to playerName,
                    "gameType" to advGameType,
                    "rssi" to scanResult.rssi,
                    "metadata" to emptyMap<String, String>()
                )
            ))
        }

        override fun onScanFailed(errorCode: Int) {
            Log.e(TAG, "Scan failed with error: $errorCode")
            sendEvent(mapOf(
                "event" to "error",
                "code" to "BLE_UNAVAILABLE",
                "message" to "Scan failed (error $errorCode)"
            ))
        }
    }

    // ========================================================================
    // Connect (Central connects to Peripheral)
    // ========================================================================

    private fun connect(call: MethodCall, result: Result) {
        val deviceId = call.argument<String>("deviceId") ?: run {
            result.error("BLE_CONNECTION_FAILED", "Device ID not provided", null)
            return
        }

        val device = discoveredDevices[deviceId] ?: run {
            result.error("BLE_CONNECTION_FAILED", "Device not found", null)
            return
        }

        localPlayerName = call.argument<String>("playerName") ?: "Player"

        bluetoothLeScanner?.stopScan(scanCallback)
        isScanning = false

        pendingConnectResult = result
        connectedGatt = device.connectGatt(context, false, gattClientCallback)
    }

    private fun disconnect(result: Result) {
        connectedGatt?.disconnect()
        connectedGatt?.close()
        connectedGatt = null
        messageCharacteristic = null
        result.success(null)
    }

    private val gattClientCallback = object : BluetoothGattCallback() {
        override fun onConnectionStateChange(gatt: BluetoothGatt, status: Int, newState: Int) {
            if (newState == BluetoothProfile.STATE_CONNECTED) {
                Log.d(TAG, "Connected to GATT server, discovering services...")
                gatt.discoverServices()
            } else if (newState == BluetoothProfile.STATE_DISCONNECTED) {
                connectedGatt = null
                messageCharacteristic = null
                sendEvent(mapOf("event" to "disconnected"))
            }
        }

        override fun onServicesDiscovered(gatt: BluetoothGatt, status: Int) {
            if (status != BluetoothGatt.GATT_SUCCESS) {
                pendingConnectResult?.error("BLE_CONNECTION_FAILED", "Service discovery failed", null)
                pendingConnectResult = null
                return
            }

            val service = gatt.getService(SERVICE_UUID)
            if (service == null) {
                pendingConnectResult?.error("BLE_CONNECTION_FAILED", "Game service not found", null)
                pendingConnectResult = null
                return
            }

            messageCharacteristic = service.getCharacteristic(MESSAGE_CHAR_UUID)
            val playerInfoChar = service.getCharacteristic(PLAYER_INFO_CHAR_UUID)

            // Subscribe to notifications
            messageCharacteristic?.let { char ->
                gatt.setCharacteristicNotification(char, true)
                val cccd = char.getDescriptor(CCCD_UUID)
                cccd?.value = BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE
                gatt.writeDescriptor(cccd)
            }

            // Read player info
            if (playerInfoChar != null) {
                // We'll read it after descriptor write completes
                mainHandler.postDelayed({
                    gatt.readCharacteristic(playerInfoChar)
                }, 500) // Small delay to let descriptor write complete
            }
        }

        override fun onCharacteristicRead(
            gatt: BluetoothGatt,
            characteristic: BluetoothGattCharacteristic,
            status: Int
        ) {
            if (characteristic.uuid == PLAYER_INFO_CHAR_UUID && status == BluetoothGatt.GATT_SUCCESS) {
                val hostName = characteristic.value?.let { String(it, StandardCharsets.UTF_8) } ?: "Unknown"

                val connection = mapOf(
                    "sessionId" to (if (sessionId.isEmpty()) UUID.randomUUID().toString() else sessionId),
                    "remoteDevice" to mapOf(
                        "id" to (gatt.device?.address ?: ""),
                        "name" to hostName,
                        "gameType" to scanningGameType,
                        "metadata" to emptyMap<String, String>()
                    ),
                    "localRole" to "joiner",
                    "connectedAt" to currentIsoTimestamp()
                )

                mainHandler.post {
                    pendingConnectResult?.success(connection)
                    pendingConnectResult = null
                }

                sendEvent(mapOf("event" to "connected", "connection" to connection))
            }
        }

        override fun onCharacteristicChanged(
            gatt: BluetoothGatt,
            characteristic: BluetoothGattCharacteristic
        ) {
            if (characteristic.uuid == MESSAGE_CHAR_UUID) {
                val data = characteristic.value
                if (data != null) {
                    val jsonString = String(data, StandardCharsets.UTF_8)
                    sendEvent(mapOf("event" to "message", "data" to jsonString))
                }
            }
        }

        override fun onCharacteristicWrite(
            gatt: BluetoothGatt,
            characteristic: BluetoothGattCharacteristic,
            status: Int
        ) {
            if (status != BluetoothGatt.GATT_SUCCESS) {
                sendEvent(mapOf(
                    "event" to "error",
                    "code" to "BLE_SEND_FAILED",
                    "message" to "Write failed with status $status"
                ))
            }
        }
    }

    // ========================================================================
    // Messaging
    // ========================================================================

    private fun sendMessage(call: MethodCall, result: Result) {
        val dataString = call.argument<String>("data") ?: run {
            result.error("BLE_SEND_FAILED", "Invalid message data", null)
            return
        }

        val data = dataString.toByteArray(StandardCharsets.UTF_8)

        if (isHosting) {
            // Host sends via notification
            val service = gattServer?.getService(SERVICE_UUID) ?: run {
                result.error("BLE_SEND_FAILED", "Service not available", null)
                return
            }
            val char = service.getCharacteristic(MESSAGE_CHAR_UUID) ?: run {
                result.error("BLE_SEND_FAILED", "Characteristic not available", null)
                return
            }

            char.value = data
            for (device in subscribedDevices) {
                gattServer?.notifyCharacteristicChanged(device, char, false)
            }
            result.success(null)
        } else {
            // Joiner writes to the characteristic
            val char = messageCharacteristic ?: run {
                result.error("BLE_SEND_FAILED", "Not connected", null)
                return
            }

            char.value = data
            char.writeType = BluetoothGattCharacteristic.WRITE_TYPE_DEFAULT
            connectedGatt?.writeCharacteristic(char)
            result.success(null)
        }
    }

    // ========================================================================
    // Helpers
    // ========================================================================

    private fun sendEvent(event: Map<String, Any?>) {
        mainHandler.post {
            eventSink?.success(event)
        }
    }

    private fun currentIsoTimestamp(): String {
        val sdf = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.US)
        sdf.timeZone = TimeZone.getTimeZone("UTC")
        return sdf.format(Date())
    }
}
