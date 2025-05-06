import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum BluetoothStatus { unavailable, available, connecting, connected }

class BluetoothController extends ChangeNotifier {
  BluetoothController() {
    _init();
  }

  final _deviceName = "XIAO_MG24 Server";

  BluetoothDevice? _device;
  StreamSubscription<BluetoothAdapterState>? _stateSubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;

  BluetoothStatus _status = BluetoothStatus.unavailable;
  BluetoothStatus get status => _status;

  Stream<int>? _heartRateStream;
  Stream<int>? get heartRateStream => _heartRateStream;
  Stream<double>? _skinTemperatureStream;
  Stream<double>? get skinTemperatureStream => _skinTemperatureStream;
  Stream<double>? _ambientTemperatureStream;
  Stream<double>? get ambientTemperatureStream => _ambientTemperatureStream;

  Future<void> _init() async {
    if (await FlutterBluePlus.isSupported == false) {
      return;
    }

    _stateSubscription = FlutterBluePlus.adapterState.listen((
      BluetoothAdapterState state,
    ) {
      _status =
          state == BluetoothAdapterState.on
              ? BluetoothStatus.available
              : BluetoothStatus.unavailable;
      notifyListeners();
    });

    if (!kIsWeb && Platform.isAndroid) {
      await FlutterBluePlus.turnOn();
    }
  }

  Future<void> connect() async {
    if (_status == BluetoothStatus.unavailable) {
      return;
    }

    final deviceFromMemory = await _getDeviceFromMemory();
    if (deviceFromMemory != null) {
      _connectToDevice(deviceFromMemory);
      return;
    }

    final scanResultsSubscription = FlutterBluePlus.onScanResults.listen((
      results,
    ) {
      if (results.isNotEmpty) {
        final device = results.last.device;
        _connectToDevice(device);
      }
    });

    FlutterBluePlus.cancelWhenScanComplete(scanResultsSubscription);

    _status = BluetoothStatus.connecting;
    notifyListeners();

    await FlutterBluePlus.startScan(
      withNames: [_deviceName],
      timeout: Duration(seconds: 5),
    );

    await FlutterBluePlus.isScanning.where((val) => val == false).first;

    if (_status == BluetoothStatus.connecting) {
      _status = BluetoothStatus.available;
      notifyListeners();
    }
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    if (_status == BluetoothStatus.connected) {
      return;
    }

    _status = BluetoothStatus.connecting;
    notifyListeners();

    _device = device;

    await device.connect(autoConnect: true);

    _connectionSubscription = device.connectionState.listen((state) async {
      if (state != BluetoothConnectionState.connected) {
        _status = BluetoothStatus.available;
        notifyListeners();
        return;
      }

      _status = BluetoothStatus.connected;
      notifyListeners();

      _saveDeviceToMemory(device);

      final services = await device.discoverServices();
      for (final service in services) {
        for (final characteristic in service.characteristics) {
          _skinTemperatureStream = characteristic.onValueReceived.map(
            (value) => double.parse(String.fromCharCodes(value).split('/')[0]),
          );
          _ambientTemperatureStream = characteristic.onValueReceived.map(
            (value) => double.parse(String.fromCharCodes(value).split('/')[1]),
          );
          _heartRateStream = characteristic.onValueReceived.map(
            (value) => int.parse(String.fromCharCodes(value).split('/')[2]),
          );

          await characteristic.setNotifyValue(true);
        }
      }
    });
  }

  Future<BluetoothDevice?> _getDeviceFromMemory() async {
    final prefs = await SharedPreferences.getInstance();
    final remoteId = prefs.getString('remoteId');
    if (remoteId == null) return null;
    return BluetoothDevice.fromId(remoteId);
  }

  Future<void> _saveDeviceToMemory(BluetoothDevice device) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('remoteId', device.remoteId.str);
  }

  Future<void> disconnect() async {
    await _device?.disconnect();
    _connectionSubscription?.cancel();
  }

  @override
  void dispose() async {
    await disconnect();
    _stateSubscription?.cancel();
    super.dispose();
  }
}
