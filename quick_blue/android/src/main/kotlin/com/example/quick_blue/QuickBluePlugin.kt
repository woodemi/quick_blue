package com.example.quick_blue

import android.bluetooth.BluetoothManager
import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanResult
import android.content.Context
import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.nio.ByteBuffer
import java.nio.ByteOrder

private const val TAG = "QuickBluePlugin"

/** QuickBluePlugin */
class QuickBluePlugin: FlutterPlugin, MethodCallHandler, EventChannel.StreamHandler {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var method : MethodChannel
  private lateinit var eventScanResult : EventChannel

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    method = MethodChannel(flutterPluginBinding.binaryMessenger, "quick_blue/method")
    eventScanResult = EventChannel(flutterPluginBinding.binaryMessenger, "quick_blue/event.scanResult")

    method.setMethodCallHandler(this)
    eventScanResult.setStreamHandler(this)

    bluetoothManager = flutterPluginBinding.applicationContext.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    bluetoothManager.adapter.bluetoothLeScanner?.stopScan(scanCallback)

    eventScanResult.setStreamHandler(null)
    method.setMethodCallHandler(null)
  }

  private lateinit var bluetoothManager: BluetoothManager

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    if (call.method == "startScan") {
      bluetoothManager.adapter.bluetoothLeScanner?.startScan(scanCallback)
    } else if (call.method == "stopScan") {
      bluetoothManager.adapter.bluetoothLeScanner?.stopScan(scanCallback)
    } else {
      result.notImplemented()
    }
  }

  private val scanCallback = object : ScanCallback() {
    override fun onScanFailed(errorCode: Int) {
      Log.v(TAG, "onScanFailed: $errorCode")
    }

    override fun onScanResult(callbackType: Int, result: ScanResult) {
      Log.v(TAG, "onScanResult: $callbackType + $result")
      scanResultSink?.success(mapOf<String, Any>(
              "name" to (result.device.name ?: ""),
              "deviceId" to result.device.address,
              "manufacturerData" to (result.manufacturerData ?: byteArrayOf()),
              "rssi" to result.rssi
      ))
    }

    override fun onBatchScanResults(results: MutableList<ScanResult>?) {
      Log.v(TAG, "onBatchScanResults: $results")
    }
  }

  private var scanResultSink: EventChannel.EventSink? = null

  override fun onListen(args: Any?, eventSink: EventChannel.EventSink?) {
    val map = args as? Map<String, Any> ?: return
    when (map["name"]) {
      "scanResult" -> scanResultSink = eventSink
    }
  }

  override fun onCancel(args: Any?) {
    val map = args as? Map<String, Any> ?: return
    when (map["name"]) {
      "scanResult" -> scanResultSink = null
    }
  }
}

val ScanResult.manufacturerData: ByteArray?
  get() {
    val sparseArray = scanRecord?.manufacturerSpecificData ?: return null
    if (sparseArray.size() == 0) return null

    return sparseArray.keyAt(0).toShort().toByteArray() + sparseArray.valueAt(0)
  }

fun Short.toByteArray(byteOrder: ByteOrder = ByteOrder.LITTLE_ENDIAN): ByteArray =
        ByteBuffer.allocate(2 /*Short.SIZE_BYTES*/).order(byteOrder).putShort(this).array()
