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

        // Message chunking constants
        /** Magic byte prefix for chunked messages (0xAA is not valid UTF-8 start for JSON). */
        const val CHUNK_MAGIC: Byte = 0xAA.toByte()
        /** Header size: [magic(1), messageId(1), chunkIndex(1), totalChunks(1)] = 4 bytes. */
        const val CHUNK_HEADER_SIZE = 4
        /** Default MTU payload (conservative: 185 - 3 ATT overhead). */
        const val DEFAULT_MAX_PAYLOAD = 182
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

    // Message chunking/reassembly
    /** Wrapping message ID counter for outgoing chunked messages. */
    private var outgoingMessageId: Byte = 0
    /** Reassembly buffer: messageId -> (totalChunks, receivedChunks map). */
    private val reassemblyBuffer = mutableMapOf<Byte, Pair<Int, MutableMap<Int, ByteArray>>>()
    /** Negotiated MTU (updated via onMtuChanged). Start conservative — actual default is 23-3=20 bytes. */
    private var negotiatedMtu: Int = 20

    // Write queue for sequential BLE writes (only one can be in-flight at a time)
    private val writeQueue: ArrayDeque<ByteArray> = ArrayDeque()
    private var isWriteInFlight = false

    // Notification queue for sequential BLE notifications (host side)
    private val notifyQueue: ArrayDeque<ByteArray> = ArrayDeque()
    private var isNotifyInFlight = false

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
                Log.d(TAG, "📥 Host received write: ${value.size} bytes from ${device.address}")
                val jsonString = reassembleOrComplete(value)
                if (jsonString != null) {
                    Log.d(TAG, "📥 Host message complete: ${jsonString.length} chars")
                    sendEvent(mapOf(
                        "event" to "message",
                        "data" to jsonString
                    ))
                } else {
                    Log.d(TAG, "📥 Host chunk buffered, waiting for more...")
                }

                if (responseNeeded) {
                    gattServer?.sendResponse(device, requestId, BluetoothGatt.GATT_SUCCESS, 0, null)
                }
            } else if (responseNeeded) {
                gattServer?.sendResponse(device, requestId, BluetoothGatt.GATT_REQUEST_NOT_SUPPORTED, 0, null)
            }
        }

        override fun onMtuChanged(device: BluetoothDevice, mtu: Int) {
            negotiatedMtu = mtu - 3 // ATT overhead
            Log.d(TAG, "Host MTU changed to $mtu, payload size: $negotiatedMtu")
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
                Log.d(TAG, "📶 Connected to GATT server, requesting MTU...")
                // Request larger MTU first, then discover services in onMtuChanged
                if (!gatt.requestMtu(517)) {
                    Log.w(TAG, "⚠️ requestMtu failed, falling back to service discovery with default MTU")
                    gatt.discoverServices()
                }
            } else if (newState == BluetoothProfile.STATE_DISCONNECTED) {
                Log.d(TAG, "📶 Disconnected from GATT server")
                connectedGatt = null
                messageCharacteristic = null
                writeQueue.clear()
                isWriteInFlight = false
                sendEvent(mapOf("event" to "disconnected"))
            }
        }

        override fun onServicesDiscovered(gatt: BluetoothGatt, status: Int) {
            if (status != BluetoothGatt.GATT_SUCCESS) {
                Log.e(TAG, "❌ Service discovery failed with status $status")
                mainHandler.post {
                    pendingConnectResult?.error("BLE_CONNECTION_FAILED", "Service discovery failed", null)
                    pendingConnectResult = null
                }
                return
            }

            val service = gatt.getService(SERVICE_UUID)
            if (service == null) {
                Log.e(TAG, "❌ Game service not found")
                mainHandler.post {
                    pendingConnectResult?.error("BLE_CONNECTION_FAILED", "Game service not found", null)
                    pendingConnectResult = null
                }
                return
            }

            Log.d(TAG, "✅ Services discovered, setting up characteristics...")
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
                    Log.d(TAG, "📥 Joiner received notification: ${data.size} bytes")
                    val jsonString = reassembleOrComplete(data)
                    if (jsonString != null) {
                        Log.d(TAG, "📥 Joiner message complete: ${jsonString.length} chars")
                        sendEvent(mapOf("event" to "message", "data" to jsonString))
                    } else {
                        Log.d(TAG, "📥 Joiner chunk buffered, waiting for more...")
                    }
                }
            }
        }

        override fun onMtuChanged(gatt: BluetoothGatt, mtu: Int, status: Int) {
            if (status == BluetoothGatt.GATT_SUCCESS) {
                negotiatedMtu = mtu - 3 // ATT overhead
                Log.d(TAG, "✅ Client MTU negotiated: $mtu bytes, payload size: $negotiatedMtu")
            } else {
                Log.w(TAG, "⚠️ MTU negotiation failed (status $status), using default MTU=$negotiatedMtu")
            }
            // Now discover services (we requested MTU before discovery)
            Log.d(TAG, "📶 Discovering services...")
            gatt.discoverServices()
        }

        override fun onCharacteristicWrite(
            gatt: BluetoothGatt,
            characteristic: BluetoothGattCharacteristic,
            status: Int
        ) {
            if (status != BluetoothGatt.GATT_SUCCESS) {
                Log.e(TAG, "❌ Write failed with status $status, queue size: ${writeQueue.size}")
                writeQueue.clear()
                isWriteInFlight = false
                sendEvent(mapOf(
                    "event" to "error",
                    "code" to "BLE_SEND_FAILED",
                    "message" to "Write failed with status $status"
                ))
            } else {
                Log.d(TAG, "✅ Write succeeded, remaining in queue: ${writeQueue.size}")
                // Process next chunk in the queue
                isWriteInFlight = false
                processWriteQueue()
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
        Log.d(TAG, "📤 sendMessage: ${data.size} bytes, isHosting=$isHosting, mtu=$negotiatedMtu")

        if (isHosting) {
            // Host sends via notification to subscribed centrals
            val service = gattServer?.getService(SERVICE_UUID) ?: run {
                Log.e(TAG, "❌ sendMessage: Service not available")
                result.error("BLE_SEND_FAILED", "Service not available", null)
                return
            }
            val char = service.getCharacteristic(MESSAGE_CHAR_UUID) ?: run {
                Log.e(TAG, "❌ sendMessage: Characteristic not available")
                result.error("BLE_SEND_FAILED", "Characteristic not available", null)
                return
            }

            if (subscribedDevices.isEmpty()) {
                Log.e(TAG, "❌ sendMessage: No subscribed devices")
                result.error("BLE_SEND_FAILED", "No connected client", null)
                return
            }

            val chunks = chunkData(data, negotiatedMtu)
            Log.d(TAG, "📤 Host sending ${chunks.size} chunk(s) to ${subscribedDevices.size} device(s)")

            // Queue notifications and send sequentially
            for (chunk in chunks) {
                notifyQueue.addLast(chunk)
            }
            processNotifyQueue()
            result.success(null)
        } else {
            // Joiner writes to the message characteristic
            val char = messageCharacteristic ?: run {
                Log.e(TAG, "❌ sendMessage: Not connected (no messageCharacteristic)")
                result.error("BLE_SEND_FAILED", "Not connected", null)
                return
            }

            if (connectedGatt == null) {
                Log.e(TAG, "❌ sendMessage: Not connected (no connectedGatt)")
                result.error("BLE_SEND_FAILED", "Not connected", null)
                return
            }

            val chunks = chunkData(data, negotiatedMtu)
            Log.d(TAG, "📤 Joiner sending ${chunks.size} chunk(s)")

            // Queue writes and send sequentially (one at a time)
            for (chunk in chunks) {
                writeQueue.addLast(chunk)
            }
            processWriteQueue()
            result.success(null)
        }
    }

    /** Process the next pending write from the queue (joiner → host). */
    private fun processWriteQueue() {
        if (isWriteInFlight || writeQueue.isEmpty()) return

        val chunk = writeQueue.removeFirst()
        val char = messageCharacteristic ?: run {
            Log.e(TAG, "❌ processWriteQueue: messageCharacteristic is null, dropping ${writeQueue.size + 1} chunks")
            writeQueue.clear()
            return
        }
        val gatt = connectedGatt ?: run {
            Log.e(TAG, "❌ processWriteQueue: connectedGatt is null, dropping ${writeQueue.size + 1} chunks")
            writeQueue.clear()
            return
        }

        isWriteInFlight = true
        char.value = chunk
        char.writeType = BluetoothGattCharacteristic.WRITE_TYPE_DEFAULT
        val success = gatt.writeCharacteristic(char)
        if (!success) {
            Log.e(TAG, "❌ writeCharacteristic returned false, dropping remaining ${writeQueue.size} chunks")
            isWriteInFlight = false
            writeQueue.clear()
            sendEvent(mapOf(
                "event" to "error",
                "code" to "BLE_SEND_FAILED",
                "message" to "writeCharacteristic returned false"
            ))
        } else {
            Log.d(TAG, "📤 Write in flight: ${chunk.size} bytes, ${writeQueue.size} remaining")
        }
    }

    /** Process the next pending notification from the queue (host → joiner). */
    private fun processNotifyQueue() {
        val service = gattServer?.getService(SERVICE_UUID) ?: return
        val char = service.getCharacteristic(MESSAGE_CHAR_UUID) ?: return

        while (notifyQueue.isNotEmpty()) {
            val chunk = notifyQueue.removeFirst()
            char.value = chunk
            var allSent = true
            for (device in subscribedDevices) {
                val sent = gattServer?.notifyCharacteristicChanged(device, char, false) ?: false
                if (!sent) {
                    Log.w(TAG, "⚠️ notifyCharacteristicChanged returned false (queue full), re-queuing")
                    // Put it back at the front and wait for peripheralManagerIsReady equivalent
                    notifyQueue.addFirst(chunk)
                    allSent = false
                    // On Android, notifyCharacteristicChanged returns false when busy.
                    // We'll retry after a short delay.
                    mainHandler.postDelayed({ processNotifyQueue() }, 50)
                    return
                }
            }
            if (allSent) {
                Log.d(TAG, "📤 Notification sent: ${chunk.size} bytes, ${notifyQueue.size} remaining")
            }
        }
    }

    // ========================================================================
    // Chunking Helpers
    // ========================================================================

    /**
     * Split data into chunks if it exceeds maxPayload bytes.
     * Single-packet messages are sent as-is (no header overhead).
     * Multi-packet messages get a 4-byte header: [0xAA, messageId, chunkIndex, totalChunks].
     */
    private fun chunkData(data: ByteArray, maxPayload: Int): List<ByteArray> {
        if (data.size <= maxPayload) {
            return listOf(data)
        }

        val msgId = outgoingMessageId
        outgoingMessageId = (outgoingMessageId + 1).toByte()

        val chunkPayloadSize = maxPayload - CHUNK_HEADER_SIZE
        if (chunkPayloadSize <= 0) return listOf(data)

        val totalChunks = (data.size + chunkPayloadSize - 1) / chunkPayloadSize
        if (totalChunks > 255) return listOf(data)

        val chunks = mutableListOf<ByteArray>()
        for (i in 0 until totalChunks) {
            val start = i * chunkPayloadSize
            val end = minOf(start + chunkPayloadSize, data.size)
            val header = byteArrayOf(CHUNK_MAGIC, msgId, i.toByte(), totalChunks.toByte())
            chunks.add(header + data.copyOfRange(start, end))
        }
        return chunks
    }

    /**
     * Process received data — either a complete message or a chunk to reassemble.
     * Returns the complete JSON string when a full message is available, or null if still buffering.
     */
    private fun reassembleOrComplete(data: ByteArray): String? {
        if (data.size >= CHUNK_HEADER_SIZE && data[0] == CHUNK_MAGIC) {
            val msgId = data[1]
            val chunkIndex = data[2].toInt() and 0xFF
            val totalChunks = data[3].toInt() and 0xFF
            val payload = data.copyOfRange(CHUNK_HEADER_SIZE, data.size)

            val entry = reassemblyBuffer.getOrPut(msgId) {
                Pair(totalChunks, mutableMapOf())
            }
            entry.second[chunkIndex] = payload

            if (entry.second.size == entry.first) {
                // All chunks received — reassemble in order
                val fullData = ByteArray(entry.second.values.sumOf { it.size })
                var offset = 0
                for (i in 0 until entry.first) {
                    val chunk = entry.second[i] ?: continue
                    System.arraycopy(chunk, 0, fullData, offset, chunk.size)
                    offset += chunk.size
                }
                reassemblyBuffer.remove(msgId)
                return String(fullData, StandardCharsets.UTF_8)
            }
            return null // Still waiting for more chunks
        }

        // Not chunked — complete single-packet message
        return String(data, StandardCharsets.UTF_8)
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
