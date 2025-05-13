import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

enum BluetoothStatus { unavailable, available, connecting, connected }

class BluetoothController extends ChangeNotifier {
  BluetoothController() {
    _init();
  }

  final _deviceName = "XIAO_MG24_TH";

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
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    if (_status == BluetoothStatus.connected) {
      return;
    }

    _status = BluetoothStatus.connecting;
    notifyListeners();

    _device = device;

    await device.connect(autoConnect: true, mtu: null);

    _connectionSubscription = device.connectionState.listen((state) async {
      if (state != BluetoothConnectionState.connected) {
        _status = BluetoothStatus.available;
        notifyListeners();
      } else {
        _status = BluetoothStatus.connected;
        notifyListeners();

        final services = await device.discoverServices();
        for (final service in services) {
          for (final characteristic in service.characteristics) {
            characteristic.onValueReceived.listen(
              (event) => print(
                "${DateTime.now()} ${String.fromCharCodes(event).split('/')}",
              ),
            );
            _skinTemperatureStream = characteristic.onValueReceived.map(
              (value) =>
                  double.parse(String.fromCharCodes(value).split('/')[0]),
            );
            _ambientTemperatureStream = characteristic.onValueReceived.map(
              (value) =>
                  double.parse(String.fromCharCodes(value).split('/')[1]),
            );
            _heartRateStream = characteristic.onValueReceived.map(
              (value) => int.parse(String.fromCharCodes(value).split('/')[2]),
            );

            await characteristic.setNotifyValue(true);
          }
        }
      }
    });
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
