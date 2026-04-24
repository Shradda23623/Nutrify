import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/device_model.dart';

class DeviceService extends ChangeNotifier {
  DeviceStatus _status = DeviceStatus.disconnected;
  List<ScanResult> _scanResults = [];
  BluetoothDevice? _connectedDevice;
  DeviceModel? _deviceModel;
  StreamSubscription? _scanSub;
  StreamSubscription? _stateSub;
  String? _errorMessage;

  DeviceStatus get status => _status;
  List<ScanResult> get scanResults => _scanResults;
  BluetoothDevice? get connectedDevice => _connectedDevice;
  DeviceModel? get deviceModel => _deviceModel;
  String? get errorMessage => _errorMessage;

  DeviceService() {
    // Listen for Bluetooth adapter state changes
    _stateSub = FlutterBluePlus.adapterState.listen((state) {
      if (state == BluetoothAdapterState.off) {
        _status = DeviceStatus.disconnected;
        _scanResults = [];
        _errorMessage = 'Bluetooth is turned off. Please enable it.';
        notifyListeners();
      } else if (state == BluetoothAdapterState.on) {
        _errorMessage = null;
        notifyListeners();
      }
    });
  }

  // ── Request all needed permissions ────────────────────────────────────────

  Future<bool> _requestPermissions() async {
    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();

    final allGranted = statuses.values.every(
      (s) => s == PermissionStatus.granted,
    );

    if (!allGranted) {
      _errorMessage =
          'Bluetooth and Location permissions are required to scan for devices.';
      notifyListeners();
    }
    return allGranted;
  }

  // ── Check if Bluetooth is ON ──────────────────────────────────────────────

  Future<bool> _isBluetoothOn() async {
    final state = await FlutterBluePlus.adapterState.first;
    if (state != BluetoothAdapterState.on) {
      _errorMessage = 'Please turn on Bluetooth and try again.';
      notifyListeners();
      return false;
    }
    return true;
  }

  // ── Start BLE scan ────────────────────────────────────────────────────────

  Future<void> startScan() async {
    _errorMessage = null;

    final hasPermission = await _requestPermissions();
    if (!hasPermission) return;

    final btOn = await _isBluetoothOn();
    if (!btOn) return;

    _status = DeviceStatus.scanning;
    _scanResults = [];
    notifyListeners();

    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 8));

      _scanSub = FlutterBluePlus.scanResults.listen((results) {
        _scanResults = results
            .where((r) => r.device.platformName.isNotEmpty)
            .toList();
        notifyListeners();
      });

      await Future.delayed(const Duration(seconds: 8));
      if (_status == DeviceStatus.scanning) await stopScan();
    } catch (e) {
      _status = DeviceStatus.disconnected;
      _errorMessage = 'Scan failed: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<void> stopScan() async {
    try {
      await FlutterBluePlus.stopScan();
    } catch (_) {}
    _scanSub?.cancel();
    if (_status == DeviceStatus.scanning) {
      _status = DeviceStatus.disconnected;
      notifyListeners();
    }
  }

  // ── Connect to a scanned BLE device ──────────────────────────────────────

  Future<void> connectDevice(ScanResult result) async {
    _errorMessage = null;
    try {
      await result.device.connect(
        autoConnect: false,
        timeout: const Duration(seconds: 10),
      );
      _connectedDevice = result.device;
      _status = DeviceStatus.connected;
      _deviceModel = DeviceModel(
        id: result.device.remoteId.str,
        name: result.device.platformName.isNotEmpty
            ? result.device.platformName
            : 'Unknown Device',
        type: 'Fitness Device',
        status: DeviceStatus.connected,
        stepCount: 0,
      );
      notifyListeners();
    } catch (e) {
      _status = DeviceStatus.disconnected;
      _errorMessage = 'Could not connect. Make sure the device is in pairing mode.';
      notifyListeners();
    }
  }

  // ── Disconnect ────────────────────────────────────────────────────────────

  Future<void> disconnect() async {
    try {
      await _connectedDevice?.disconnect();
    } catch (_) {}
    _connectedDevice = null;
    _deviceModel = null;
    _status = DeviceStatus.disconnected;
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    _stateSub?.cancel();
    super.dispose();
  }
}
