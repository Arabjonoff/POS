package uz.zellypos.pos_app

import android.Manifest
import android.app.Activity
import android.app.PendingIntent
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothClass
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothSocket
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.hardware.usb.UsbConstants
import android.hardware.usb.UsbDevice
import android.hardware.usb.UsbEndpoint
import android.hardware.usb.UsbInterface
import android.hardware.usb.UsbManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.IOException
import java.util.UUID
import java.util.concurrent.Executors

/**
 * Chek printeri: Bluetooth SPP (RFCOMM) va USB host (bulk OUT), T-047.
 * Dart tomoni — `android_printer_channel.dart`. Baytlar tayyor ESC/POS.
 *
 * Xato kodlari: `bluetooth_off`, `permission_denied`, `not_found`, `io`.
 * Chop etish ketma-ket (bitta oqim), asosiy oqim bloklanmaydi.
 */
class PrinterChannel(
    private val activity: Activity,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler {
    companion object {
        const val CHANNEL = "uz.zellypos.pos/printer"
        const val BLUETOOTH_PERMISSION_REQUEST = 4701
        private const val USB_PERMISSION = "uz.zellypos.pos_app.USB_PERMISSION"
        private val SPP_UUID: UUID = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB")
        private const val BLUETOOTH_CHUNK = 1024
        private const val USB_CHUNK = 16384
        private const val USB_TIMEOUT_MS = 5000
    }

    private val channel = MethodChannel(messenger, CHANNEL)
    private val io = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())

    /** Ruxsat javobini kutayotgan Bluetooth amallari (true — ruxsat berildi). */
    private val waitingForBluetooth = mutableListOf<(Boolean) -> Unit>()

    init {
        channel.setMethodCallHandler(this)
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
        io.shutdown()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        val id = call.argument<String>("id") ?: ""
        when (call.method) {
            "bluetoothDevices" -> withBluetooth(result) { adapter ->
                result.success(bondedDevices(adapter))
            }
            "bluetoothSend" -> {
                val bytes = call.argument<ByteArray>("bytes") ?: ByteArray(0)
                withBluetooth(result) { adapter ->
                    background(result) { sendBluetooth(adapter, id, bytes) }
                }
            }
            "bluetoothAvailable" -> result.success(bluetoothAvailable(id))
            "usbDevices" -> result.success(usbDevices())
            "usbSend" -> {
                val bytes = call.argument<ByteArray>("bytes") ?: ByteArray(0)
                val device = findUsb(id)
                if (device == null) {
                    result.error("not_found", "USB printer $id", null)
                } else {
                    withUsbPermission(device, result) {
                        background(result) { sendUsb(device, bytes) }
                    }
                }
            }
            "usbAvailable" -> result.success(findUsb(id) != null)
            else -> result.notImplemented()
        }
    }

    // ---------------------------------------------------------------- Bluetooth

    private fun adapter(): BluetoothAdapter? =
        (activity.getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager)?.adapter

    private fun hasBluetoothPermission(): Boolean =
        Build.VERSION.SDK_INT < Build.VERSION_CODES.S ||
            activity.checkSelfPermission(Manifest.permission.BLUETOOTH_CONNECT) ==
            PackageManager.PERMISSION_GRANTED

    /** Android 12+ da `BLUETOOTH_CONNECT` so'raladi; Bluetooth o'chiq — xato. */
    private fun withBluetooth(result: MethodChannel.Result, action: (BluetoothAdapter) -> Unit) {
        val run: (Boolean) -> Unit = { granted ->
            val adapter = adapter()
            when {
                !granted -> result.error("permission_denied", "BLUETOOTH_CONNECT", null)
                adapter == null || !adapter.isEnabled ->
                    result.error("bluetooth_off", "Bluetooth is off", null)
                else -> try {
                    action(adapter)
                } catch (e: SecurityException) {
                    result.error("permission_denied", e.message, null)
                }
            }
        }
        if (hasBluetoothPermission()) {
            run(true)
            return
        }
        waitingForBluetooth.add(run)
        if (waitingForBluetooth.size == 1 && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            activity.requestPermissions(
                arrayOf(Manifest.permission.BLUETOOTH_CONNECT),
                BLUETOOTH_PERMISSION_REQUEST,
            )
        }
    }

    fun onRequestPermissionsResult(requestCode: Int, grantResults: IntArray) {
        if (requestCode != BLUETOOTH_PERMISSION_REQUEST) return
        val granted = grantResults.isNotEmpty() &&
            grantResults.all { it == PackageManager.PERMISSION_GRANTED }
        val waiting = waitingForBluetooth.toList()
        waitingForBluetooth.clear()
        waiting.forEach { it(granted) }
    }

    /** Juftlangan qurilmalar: printerlar (IMAGING) birinchi, keyin nom bo'yicha. */
    private fun bondedDevices(adapter: BluetoothAdapter): List<Map<String, String>> =
        adapter.bondedDevices
            .sortedWith(
                compareBy<BluetoothDevice>(
                    { it.bluetoothClass?.majorDeviceClass != BluetoothClass.Device.Major.IMAGING },
                    { it.name ?: "" },
                ),
            )
            .map { mapOf("id" to it.address, "name" to (it.name ?: "")) }

    private fun bluetoothAvailable(id: String): Boolean {
        if (!hasBluetoothPermission()) return false
        val adapter = adapter() ?: return false
        return try {
            adapter.isEnabled && adapter.bondedDevices.any { it.address == id }
        } catch (e: SecurityException) {
            false
        }
    }

    private fun sendBluetooth(adapter: BluetoothAdapter, id: String, bytes: ByteArray) {
        if (!BluetoothAdapter.checkBluetoothAddress(id)) throw IOException("Bad address $id")
        val device = adapter.getRemoteDevice(id)
        try {
            // Qidiruv ulanishni sekinlashtiradi; Android 12+ da BLUETOOTH_SCAN kerak.
            adapter.cancelDiscovery()
        } catch (e: SecurityException) {
            // Ruxsat yo'q — qidiruv ham ishlamayapti.
        }
        val socket = connect(device)
        try {
            val out = socket.outputStream
            var offset = 0
            while (offset < bytes.size) {
                val length = minOf(BLUETOOTH_CHUNK, bytes.size - offset)
                out.write(bytes, offset, length)
                offset += length
            }
            out.flush()
            // Arzon printerlar buferi kichik: ulanish erta yopilsa chek oxiri yo'qoladi.
            Thread.sleep(minOf(3000L, 300L + bytes.size / 8L))
        } finally {
            try {
                socket.close()
            } catch (e: IOException) {
                // Yopishdagi xato chekni buzmaydi.
            }
        }
    }

    /** Avval xavfsiz RFCOMM, bo'lmasa — xavfsiz bo'lmagan (ba'zi printerlar faqat shuni qo'llaydi). */
    private fun connect(device: BluetoothDevice): BluetoothSocket {
        val secure = device.createRfcommSocketToServiceRecord(SPP_UUID)
        try {
            secure.connect()
            return secure
        } catch (e: IOException) {
            try {
                secure.close()
            } catch (ignored: IOException) {
            }
        }
        val insecure = device.createInsecureRfcommSocketToServiceRecord(SPP_UUID)
        try {
            insecure.connect()
        } catch (e: IOException) {
            try {
                insecure.close()
            } catch (ignored: IOException) {
            }
            throw e
        }
        return insecure
    }

    // ---------------------------------------------------------------------- USB

    private fun usbManager(): UsbManager? =
        activity.getSystemService(Context.USB_SERVICE) as? UsbManager

    private fun usbId(device: UsbDevice) = "${device.vendorId}:${device.productId}"

    /** Bulk OUT nuqtasi bor qurilmalar (skaner/klaviatura — HID, ro'yxatga tushmaydi). */
    private fun usbDevices(): List<Map<String, String>> =
        (usbManager()?.deviceList?.values ?: emptyList())
            .filter { printerEndpoint(it) != null }
            .map { device ->
                val name = listOfNotNull(device.manufacturerName, device.productName)
                    .joinToString(" ")
                    .trim()
                mapOf("id" to usbId(device), "name" to name.ifEmpty { device.deviceName })
            }

    private fun findUsb(id: String): UsbDevice? =
        usbManager()?.deviceList?.values?.firstOrNull {
            usbId(it) == id && printerEndpoint(it) != null
        }

    /** Printer sinfi (7) birinchi; bo'lmasa — bulk OUT bor istalgan interfeys. */
    private fun printerEndpoint(device: UsbDevice): Pair<UsbInterface, UsbEndpoint>? {
        val interfaces = (0 until device.interfaceCount).map { device.getInterface(it) }
            .sortedBy { if (it.interfaceClass == UsbConstants.USB_CLASS_PRINTER) 0 else 1 }
        for (intf in interfaces) {
            for (i in 0 until intf.endpointCount) {
                val endpoint = intf.getEndpoint(i)
                if (endpoint.type == UsbConstants.USB_ENDPOINT_XFER_BULK &&
                    endpoint.direction == UsbConstants.USB_DIR_OUT
                ) {
                    return intf to endpoint
                }
            }
        }
        return null
    }

    private fun withUsbPermission(
        device: UsbDevice,
        result: MethodChannel.Result,
        action: () -> Unit,
    ) {
        val manager = usbManager()
        if (manager == null) {
            result.error("not_found", "USB host", null)
            return
        }
        if (manager.hasPermission(device)) {
            action()
            return
        }
        val receiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent) {
                if (intent.action != USB_PERMISSION) return
                activity.unregisterReceiver(this)
                if (intent.getBooleanExtra(UsbManager.EXTRA_PERMISSION_GRANTED, false)) {
                    action()
                } else {
                    result.error("permission_denied", "USB", null)
                }
            }
        }
        val filter = IntentFilter(USB_PERMISSION)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            activity.registerReceiver(receiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            @Suppress("UnspecifiedRegisterReceiverFlag")
            activity.registerReceiver(receiver, filter)
        }
        // Android 12+: tizim ruxsat natijasini intent'ga yozadi — MUTABLE, paket aniq.
        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            PendingIntent.FLAG_MUTABLE
        } else {
            0
        }
        val intent = Intent(USB_PERMISSION).setPackage(activity.packageName)
        manager.requestPermission(
            device,
            PendingIntent.getBroadcast(activity, 0, intent, flags),
        )
    }

    private fun sendUsb(device: UsbDevice, bytes: ByteArray) {
        val manager = usbManager() ?: throw IOException("No USB host")
        val (intf, endpoint) = printerEndpoint(device) ?: throw IOException("No bulk OUT")
        val connection = manager.openDevice(device) ?: throw IOException("Cannot open USB")
        try {
            if (!connection.claimInterface(intf, true)) throw IOException("Cannot claim USB")
            var offset = 0
            while (offset < bytes.size) {
                val length = minOf(USB_CHUNK, bytes.size - offset)
                val sent = connection.bulkTransfer(endpoint, bytes, offset, length, USB_TIMEOUT_MS)
                if (sent <= 0) throw IOException("USB write failed")
                offset += sent
            }
            connection.releaseInterface(intf)
        } finally {
            connection.close()
        }
    }

    // ------------------------------------------------------------------ Umumiy

    /** Uzoq amal fon oqimida; javob — asosiy oqimda. */
    private fun background(result: MethodChannel.Result, work: () -> Unit) {
        io.execute {
            try {
                work()
                main.post { result.success(null) }
            } catch (e: SecurityException) {
                main.post { result.error("permission_denied", e.message, null) }
            } catch (e: Exception) {
                main.post { result.error("io", e.message, null) }
            }
        }
    }
}
