import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

enum BluetoothStatus { unavailable, available, connecting, connected }

class BluetoothController extends ChangeNotifier {
  BluetoothController() {
    _init();
  }

  final _deviceName = "XIAO";

  BluetoothDevice? _device;
  StreamSubscription<BluetoothAdapterState>? _stateSubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;

  BluetoothStatus _status = BluetoothStatus.unavailable;
  BluetoothStatus get status => _status;

  Stream? _valueStream;
  Stream? get valueStream => _valueStream;

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

    var subscription = FlutterBluePlus.onScanResults.listen((results) {
      if (results.isNotEmpty) {
        final device = results.last.device;
        _connectToDevice(device);
      }
    });

    FlutterBluePlus.cancelWhenScanComplete(subscription);

    await FlutterBluePlus.startScan(
      withServices: [Guid("180D")],
      withNames: [_deviceName],
      timeout: Duration(seconds: 15),
    );

    await FlutterBluePlus.isScanning.where((val) => val == false).first;
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    if (_status == BluetoothStatus.connected) {
      return;
    }
    _device = device;

    _status = BluetoothStatus.connecting;
    notifyListeners();

    await device.connect(autoConnect: true, mtu: null);

    _connectionSubscription = device.connectionState.listen((state) async {
      if (state == BluetoothConnectionState.connected) {
        _status = BluetoothStatus.connected;
        notifyListeners();

        _saveDeviceToMemory(device);

        final services = await device.discoverServices();
        for (final service in services) {
          final characteristics = service.characteristics;
          if (characteristics.isNotEmpty) {
            _valueStream = characteristics.first.onValueReceived;
          }
        }
      } else {
        _status = BluetoothStatus.available;
        notifyListeners();
      }
    });
  }

  Future<BluetoothDevice?> _getDeviceFromMemory() async {
    return null;
  }

  Future<void> _saveDeviceToMemory(BluetoothDevice device) async {
    // https://pub.dev/packages/flutter_blue_plus#save-device
  }

  @override
  void dispose() async {
    await _device?.disconnect();
    _stateSubscription?.cancel();
    _connectionSubscription?.cancel();
    super.dispose();
  }
}
