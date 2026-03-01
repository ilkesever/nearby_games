import Flutter
import UIKit
import CoreBluetooth

/// Flutter plugin for BLE-based nearby communication on iOS.
///
/// Uses CoreBluetooth to implement both Central (scanner/joiner) and
/// Peripheral (advertiser/host) roles for cross-platform P2P gaming.
public class NearbyBlePlugin: NSObject, FlutterPlugin {

    // MARK: - Constants

    /// Base UUID for nearby games BLE service.
    /// Game type is encoded in the advertising data, not in the UUID.
    private static let serviceUUID = CBUUID(string: "A1B2C3D4-E5F6-7890-ABCD-EF1234567890")
    private static let messageCharUUID = CBUUID(string: "A1B2C3D4-E5F6-7890-ABCD-EF1234567891")
    private static let playerInfoCharUUID = CBUUID(string: "A1B2C3D4-E5F6-7890-ABCD-EF1234567892")

    // MARK: - Properties

    private var channel: FlutterMethodChannel?
    private var eventSink: FlutterEventSink?

    // Central (scanner/joiner)
    private var centralManager: CBCentralManager?
    private var discoveredPeripherals: [String: CBPeripheral] = [:]
    private var connectedPeripheral: CBPeripheral?
    private var messageCharacteristic: CBCharacteristic?

    // Peripheral (advertiser/host)
    private var peripheralManager: CBPeripheralManager?
    private var gameService: CBMutableService?
    private var messageChar: CBMutableCharacteristic?
    private var playerInfoChar: CBMutableCharacteristic?
    private var connectedCentral: CBCentral?
    private var subscribedCentrals: [CBCentral] = []

    // BLE dispatch queue — avoids blocking the main/UI thread
    private let bleQueue = DispatchQueue(label: "com.nearbygames.ble", qos: .userInitiated)

    // State
    private var localPlayerName: String = "Player"
    private var gameType: String = ""
    private var scanningGameType: String = ""
    private var sessionId: String = ""
    private var isHosting = false
    private var isScanning = false

    // Message chunking/reassembly
    /// Magic byte prefix for chunked messages (0xAA is not valid UTF-8 start for JSON).
    private static let chunkMagic: UInt8 = 0xAA
    /// Header size: [magic(1), messageId(1), chunkIndex(1), totalChunks(1)] = 4 bytes.
    private static let chunkHeaderSize = 4
    /// Wrapping message ID counter for outgoing chunked messages.
    private var outgoingMessageId: UInt8 = 0
    /// Reassembly buffer: messageId -> (totalChunks, receivedChunks dict)
    private var reassemblyBuffer: [UInt8: (total: UInt8, chunks: [UInt8: Data])] = [:]

    // MARK: - Plugin Registration

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "com.nearbygames/nearby_ble",
            binaryMessenger: registrar.messenger()
        )
        let eventChannel = FlutterEventChannel(
            name: "com.nearbygames/nearby_ble/events",
            binaryMessenger: registrar.messenger()
        )

        let instance = NearbyBlePlugin()
        instance.channel = channel
        registrar.addMethodCallDelegate(instance, channel: channel)
        eventChannel.setStreamHandler(instance)
    }

    // MARK: - Method Channel Handler

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "initialize":
            initialize(result: result)
        case "isAvailable":
            isAvailable(result: result)
        case "requestPermissions":
            requestPermissions(result: result)
        case "startHosting":
            let args = call.arguments as? [String: Any] ?? [:]
            startHosting(args: args, result: result)
        case "stopHosting":
            stopHosting(result: result)
        case "startScanning":
            let args = call.arguments as? [String: Any] ?? [:]
            startScanning(args: args, result: result)
        case "stopScanning":
            stopScanning(result: result)
        case "connect":
            let args = call.arguments as? [String: Any] ?? [:]
            connect(args: args, result: result)
        case "disconnect":
            disconnect(result: result)
        case "sendMessage":
            let args = call.arguments as? [String: Any] ?? [:]
            sendMessage(args: args, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Initialize

    private func initialize(result: @escaping FlutterResult) {
        centralManager = CBCentralManager(delegate: self, queue: bleQueue)
        peripheralManager = CBPeripheralManager(delegate: self, queue: bleQueue)
        result(nil)
    }

    private func isAvailable(result: @escaping FlutterResult) {
        let state = centralManager?.state ?? .unknown
        result(state == .poweredOn)
    }

    private func requestPermissions(result: @escaping FlutterResult) {
        // iOS handles BLE permissions through Info.plist and system prompts.
        // CoreBluetooth triggers the prompt automatically on first use.
        // We just check the current state.
        let state = centralManager?.state ?? .unknown
        switch state {
        case .poweredOn:
            result(true)
        case .unauthorized:
            result(FlutterError(code: "BLE_PERMISSION_DENIED",
                              message: "Bluetooth permission denied",
                              details: nil))
        case .poweredOff:
            result(FlutterError(code: "BLE_DISABLED",
                              message: "Bluetooth is turned off",
                              details: nil))
        default:
            result(FlutterError(code: "BLE_UNAVAILABLE",
                              message: "Bluetooth is not available",
                              details: nil))
        }
    }

    // MARK: - Host Mode (Peripheral)

    private func startHosting(args: [String: Any], result: @escaping FlutterResult) {
        guard peripheralManager?.state == .poweredOn else {
            result(FlutterError(code: "BLE_DISABLED",
                              message: "Bluetooth is not enabled",
                              details: nil))
            return
        }

        gameType = args["gameType"] as? String ?? "unknown"
        localPlayerName = args["playerName"] as? String ?? "Player"
        sessionId = UUID().uuidString

        // Create GATT service with characteristics
        messageChar = CBMutableCharacteristic(
            type: NearbyBlePlugin.messageCharUUID,
            properties: [.write, .notify, .writeWithoutResponse],
            value: nil,
            permissions: [.writeable, .readable]
        )

        let playerData = localPlayerName.data(using: .utf8)
        playerInfoChar = CBMutableCharacteristic(
            type: NearbyBlePlugin.playerInfoCharUUID,
            properties: [.read],
            value: playerData,
            permissions: [.readable]
        )

        gameService = CBMutableService(type: NearbyBlePlugin.serviceUUID, primary: true)
        gameService?.characteristics = [messageChar!, playerInfoChar!]

        peripheralManager?.add(gameService!)

        // Start advertising
        let advertisementData: [String: Any] = [
            CBAdvertisementDataServiceUUIDsKey: [NearbyBlePlugin.serviceUUID],
            CBAdvertisementDataLocalNameKey: "\(gameType)|\(localPlayerName)"
        ]
        peripheralManager?.startAdvertising(advertisementData)
        isHosting = true

        result(nil)
    }

    private func stopHosting(result: @escaping FlutterResult) {
        peripheralManager?.stopAdvertising()
        if let service = gameService {
            peripheralManager?.remove(service)
        }
        isHosting = false
        subscribedCentrals.removeAll()
        connectedCentral = nil
        result(nil)
    }

    // MARK: - Join Mode (Central)

    private func startScanning(args: [String: Any], result: @escaping FlutterResult) {
        guard centralManager?.state == .poweredOn else {
            result(FlutterError(code: "BLE_DISABLED",
                              message: "Bluetooth is not enabled",
                              details: nil))
            return
        }

        scanningGameType = args["gameType"] as? String ?? ""
        discoveredPeripherals.removeAll()

        centralManager?.scanForPeripherals(
            withServices: [NearbyBlePlugin.serviceUUID],
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
        )
        isScanning = true

        result(nil)
    }

    private func stopScanning(result: @escaping FlutterResult) {
        centralManager?.stopScan()
        isScanning = false
        result(nil)
    }

    private func connect(args: [String: Any], result: @escaping FlutterResult) {
        guard let deviceId = args["deviceId"] as? String,
              let peripheral = discoveredPeripherals[deviceId] else {
            result(FlutterError(code: "BLE_CONNECTION_FAILED",
                              message: "Device not found",
                              details: nil))
            return
        }

        localPlayerName = args["playerName"] as? String ?? "Player"
        connectedPeripheral = peripheral
        peripheral.delegate = self

        centralManager?.stopScan()
        isScanning = false
        centralManager?.connect(peripheral, options: nil)

        // We'll send the result back asynchronously when connection succeeds
        // Store the result callback
        pendingConnectResult = result
    }

    private var pendingConnectResult: FlutterResult?

    private func disconnect(result: @escaping FlutterResult) {
        if let peripheral = connectedPeripheral {
            centralManager?.cancelPeripheralConnection(peripheral)
        }
        connectedPeripheral = nil
        messageCharacteristic = nil
        connectedCentral = nil
        subscribedCentrals.removeAll()
        result(nil)
    }

    // MARK: - Messaging

    // Notification queue for host side (retry when updateValue returns false)
    private var pendingNotifications: [Data] = []

    private func sendMessage(args: [String: Any], result: @escaping FlutterResult) {
        guard let dataString = args["data"] as? String,
              let data = dataString.data(using: .utf8) else {
            result(FlutterError(code: "BLE_SEND_FAILED",
                              message: "Invalid message data",
                              details: nil))
            return
        }

        if isHosting {
            // Host sends via notification to subscribed centrals
            guard let char = messageChar, !subscribedCentrals.isEmpty else {
                result(FlutterError(code: "BLE_SEND_FAILED",
                                  message: "No connected client",
                                  details: nil))
                return
            }

            // Determine max payload for notifications: use first subscribed central's MTU
            let mtu = subscribedCentrals.first?.maximumUpdateValueLength ?? 182
            let chunks = chunkData(data, maxPayload: mtu)

            for chunk in chunks {
                let sent = peripheralManager?.updateValue(
                    chunk,
                    for: char,
                    onSubscribedCentrals: subscribedCentrals
                ) ?? false
                if !sent {
                    // Queue is full — buffer remaining chunks for retry in peripheralManagerIsReady
                    pendingNotifications.append(chunk)
                }
            }
            result(nil)
        } else {
            // Joiner sends via write to the message characteristic
            guard let peripheral = connectedPeripheral,
                  let characteristic = messageCharacteristic else {
                result(FlutterError(code: "BLE_SEND_FAILED",
                                  message: "Not connected",
                                  details: nil))
                return
            }

            // For write-with-response, CoreBluetooth handles ATT segmentation,
            // but we chunk to stay within the negotiated MTU for reliability.
            let mtu = peripheral.maximumWriteValueLength(for: .withResponse)
            let chunks = chunkData(data, maxPayload: mtu)

            for chunk in chunks {
                peripheral.writeValue(chunk, for: characteristic, type: .withResponse)
            }
            result(nil)
        }
    }

    // MARK: - Chunking Helpers

    /// Split data into chunks if it exceeds maxPayload bytes.
    /// Single-packet messages are sent as-is (no header overhead).
    /// Multi-packet messages get a 4-byte header: [0xAA, messageId, chunkIndex, totalChunks].
    private func chunkData(_ data: Data, maxPayload: Int) -> [Data] {
        if data.count <= maxPayload {
            // Fits in a single packet — send as-is, no chunking header
            return [data]
        }

        let msgId = outgoingMessageId
        outgoingMessageId = outgoingMessageId &+ 1

        let chunkPayloadSize = maxPayload - NearbyBlePlugin.chunkHeaderSize
        guard chunkPayloadSize > 0 else { return [data] }

        let totalChunks = (data.count + chunkPayloadSize - 1) / chunkPayloadSize
        guard totalChunks <= 255 else {
            // Message too large even for chunking — send raw and hope for the best
            return [data]
        }

        var chunks: [Data] = []
        for i in 0..<totalChunks {
            let start = i * chunkPayloadSize
            let end = min(start + chunkPayloadSize, data.count)
            var chunk = Data([NearbyBlePlugin.chunkMagic, msgId, UInt8(i), UInt8(totalChunks)])
            chunk.append(data[start..<end])
            chunks.append(chunk)
        }
        return chunks
    }

    /// Process received data — either a complete message or a chunk to reassemble.
    /// Returns the complete JSON string when a full message is available, or nil if still buffering.
    private func reassembleOrComplete(_ data: Data) -> String? {
        // Check if this is a chunked message (starts with magic byte)
        if data.count >= NearbyBlePlugin.chunkHeaderSize && data[0] == NearbyBlePlugin.chunkMagic {
            let msgId = data[1]
            let chunkIndex = data[2]
            let totalChunks = data[3]
            let payload = data.subdata(in: NearbyBlePlugin.chunkHeaderSize..<data.count)

            // Initialize buffer for this message ID if needed
            if reassemblyBuffer[msgId] == nil {
                reassemblyBuffer[msgId] = (total: totalChunks, chunks: [:])
            }

            reassemblyBuffer[msgId]?.chunks[chunkIndex] = payload

            // Check if all chunks received
            if let entry = reassemblyBuffer[msgId],
               entry.chunks.count == Int(entry.total) {
                // Reassemble in order
                var fullData = Data()
                for i in 0..<entry.total {
                    if let chunk = entry.chunks[i] {
                        fullData.append(chunk)
                    }
                }
                reassemblyBuffer.removeValue(forKey: msgId)
                return String(data: fullData, encoding: .utf8)
            }
            return nil // Still waiting for more chunks
        }

        // Not chunked — complete single-packet message
        return String(data: data, encoding: .utf8)
    }

    // MARK: - Event Helpers

    private func sendEvent(_ event: [String: Any]) {
        DispatchQueue.main.async { [weak self] in
            self?.eventSink?(event)
        }
    }
}

// MARK: - CBCentralManagerDelegate (Scanner/Joiner)

extension NearbyBlePlugin: CBCentralManagerDelegate {

    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        // State updates are handled by isAvailable/requestPermissions
    }

    public func centralManager(_ central: CBCentralManager,
                               didDiscover peripheral: CBPeripheral,
                               advertisementData: [String: Any],
                               rssi RSSI: NSNumber) {
        let id = peripheral.identifier.uuidString
        discoveredPeripherals[id] = peripheral

        // Parse advertised name: "gameType|playerName"
        let localName = advertisementData[CBAdvertisementDataLocalNameKey] as? String ?? ""
        let parts = localName.split(separator: "|", maxSplits: 1)
        let advGameType = parts.count > 0 ? String(parts[0]) : "unknown"
        let playerName = parts.count > 1 ? String(parts[1]) : "Unknown Player"

        // Filter by game type
        if !scanningGameType.isEmpty && advGameType != scanningGameType {
            return
        }

        sendEvent([
            "event": "deviceFound",
            "device": [
                "id": id,
                "name": playerName,
                "gameType": advGameType,
                "rssi": RSSI.intValue,
                "metadata": [:] as [String: String]
            ]
        ])
    }

    public func centralManager(_ central: CBCentralManager,
                               didConnect peripheral: CBPeripheral) {
        // Discover our game service
        peripheral.discoverServices([NearbyBlePlugin.serviceUUID])
    }

    public func centralManager(_ central: CBCentralManager,
                               didFailToConnect peripheral: CBPeripheral,
                               error: Error?) {
        pendingConnectResult?(FlutterError(
            code: "BLE_CONNECTION_FAILED",
            message: error?.localizedDescription ?? "Failed to connect",
            details: nil
        ))
        pendingConnectResult = nil
    }

    public func centralManager(_ central: CBCentralManager,
                               didDisconnectPeripheral peripheral: CBPeripheral,
                               error: Error?) {
        connectedPeripheral = nil
        messageCharacteristic = nil

        sendEvent([
            "event": "disconnected"
        ])
    }
}

// MARK: - CBPeripheralDelegate (for Central role — discovering services/characteristics)

extension NearbyBlePlugin: CBPeripheralDelegate {

    public func peripheral(_ peripheral: CBPeripheral,
                           didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }

        for service in services {
            if service.uuid == NearbyBlePlugin.serviceUUID {
                peripheral.discoverCharacteristics(
                    [NearbyBlePlugin.messageCharUUID, NearbyBlePlugin.playerInfoCharUUID],
                    for: service
                )
            }
        }
    }

    public func peripheral(_ peripheral: CBPeripheral,
                           didDiscoverCharacteristicsFor service: CBService,
                           error: Error?) {
        guard let characteristics = service.characteristics else { return }

        for char in characteristics {
            if char.uuid == NearbyBlePlugin.messageCharUUID {
                messageCharacteristic = char
                // Subscribe to notifications from host
                peripheral.setNotifyValue(true, for: char)
            } else if char.uuid == NearbyBlePlugin.playerInfoCharUUID {
                peripheral.readValue(for: char)
            }
        }
    }

    public func peripheral(_ peripheral: CBPeripheral,
                           didUpdateValueFor characteristic: CBCharacteristic,
                           error: Error?) {
        if characteristic.uuid == NearbyBlePlugin.messageCharUUID {
            // Received a message (or chunk) from host
            if let data = characteristic.value,
               let jsonString = reassembleOrComplete(data) {
                sendEvent([
                    "event": "message",
                    "data": jsonString
                ])
            }
        } else if characteristic.uuid == NearbyBlePlugin.playerInfoCharUUID {
            // Got the host's player name
            if let data = characteristic.value,
               let hostName = String(data: data, encoding: .utf8) {
                let connection: [String: Any] = [
                    "sessionId": sessionId.isEmpty ? UUID().uuidString : sessionId,
                    "remoteDevice": [
                        "id": peripheral.identifier.uuidString,
                        "name": hostName,
                        "gameType": scanningGameType,
                        "metadata": [:] as [String: String]
                    ],
                    "localRole": "joiner",
                    "connectedAt": ISO8601DateFormatter().string(from: Date())
                ]

                // Complete the pending connect call
                pendingConnectResult?(connection)
                pendingConnectResult = nil

                sendEvent([
                    "event": "connected",
                    "connection": connection
                ])
            }
        }
    }

    public func peripheral(_ peripheral: CBPeripheral,
                           didWriteValueFor characteristic: CBCharacteristic,
                           error: Error?) {
        if let error = error {
            sendEvent([
                "event": "error",
                "code": "BLE_SEND_FAILED",
                "message": error.localizedDescription
            ])
        }
    }

    public func peripheral(_ peripheral: CBPeripheral,
                           didUpdateNotificationStateFor characteristic: CBCharacteristic,
                           error: Error?) {
        // Notification subscription updated
    }
}

// MARK: - CBPeripheralManagerDelegate (Advertiser/Host)

extension NearbyBlePlugin: CBPeripheralManagerDelegate {

    public func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        // State updates handled by isAvailable/requestPermissions
    }

    public func peripheralManager(_ peripheral: CBPeripheralManager,
                                  didAdd service: CBService,
                                  error: Error?) {
        if let error = error {
            sendEvent([
                "event": "error",
                "code": "BLE_UNAVAILABLE",
                "message": "Failed to add service: \(error.localizedDescription)"
            ])
        }
    }

    public func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager,
                                                     error: Error?) {
        if let error = error {
            sendEvent([
                "event": "error",
                "code": "BLE_UNAVAILABLE",
                "message": "Failed to start advertising: \(error.localizedDescription)"
            ])
        }
    }

    public func peripheralManager(_ peripheral: CBPeripheralManager,
                                  central: CBCentral,
                                  didSubscribeTo characteristic: CBCharacteristic) {
        // A joiner subscribed to our message characteristic
        subscribedCentrals.append(central)
        connectedCentral = central

        let connection: [String: Any] = [
            "sessionId": sessionId,
            "remoteDevice": [
                "id": central.identifier.uuidString,
                "name": "Opponent", // We'll get the real name via message
                "gameType": gameType,
                "metadata": [:] as [String: String]
            ],
            "localRole": "host",
            "connectedAt": ISO8601DateFormatter().string(from: Date())
        ]

        sendEvent([
            "event": "connected",
            "connection": connection
        ])
    }

    public func peripheralManager(_ peripheral: CBPeripheralManager,
                                  central: CBCentral,
                                  didUnsubscribeFrom characteristic: CBCharacteristic) {
        subscribedCentrals.removeAll { $0.identifier == central.identifier }
        if subscribedCentrals.isEmpty {
            connectedCentral = nil
            sendEvent(["event": "disconnected"])
        }
    }

    public func peripheralManager(_ peripheral: CBPeripheralManager,
                                  didReceiveWrite requests: [CBATTRequest]) {
        for request in requests {
            if request.characteristic.uuid == NearbyBlePlugin.messageCharUUID {
                if let data = request.value,
                   let jsonString = reassembleOrComplete(data) {
                    sendEvent([
                        "event": "message",
                        "data": jsonString
                    ])
                }
                peripheral.respond(to: request, withResult: .success)
            } else {
                peripheral.respond(to: request, withResult: .requestNotSupported)
            }
        }
    }

    public func peripheralManager(_ peripheral: CBPeripheralManager,
                                  didReceiveRead request: CBATTRequest) {
        if request.characteristic.uuid == NearbyBlePlugin.playerInfoCharUUID {
            if let data = localPlayerName.data(using: .utf8) {
                request.value = data
                peripheral.respond(to: request, withResult: .success)
            } else {
                peripheral.respond(to: request, withResult: .attributeNotFound)
            }
        } else {
            peripheral.respond(to: request, withResult: .requestNotSupported)
        }
    }

    public func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
        // Called when the transmit queue has space again — retry pending notifications.
        guard let char = messageChar, !pendingNotifications.isEmpty else { return }

        while !pendingNotifications.isEmpty {
            let chunk = pendingNotifications[0]
            let sent = peripheral.updateValue(
                chunk,
                for: char,
                onSubscribedCentrals: subscribedCentrals
            )
            if sent {
                pendingNotifications.removeFirst()
            } else {
                // Still full, will be called again when ready
                break
            }
        }
    }
}

// MARK: - FlutterStreamHandler (Event Channel)

extension NearbyBlePlugin: FlutterStreamHandler {

    public func onListen(withArguments arguments: Any?,
                         eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }
}
