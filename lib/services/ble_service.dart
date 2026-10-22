import 'dart:convert';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleService {
  static const String serviceUuid = '6f400001-b5a3-f393-e0a9-e50e24dcca9e';
  static const String commandCharacteristicUuid =
      '6f400002-b5a3-f393-e0a9-e50e24dcca9e';
  static const String deviceName = 'RoletaESP32';

  BluetoothDevice? _device;
  BluetoothCharacteristic? _commandCharacteristic;

  bool get isConnected => _device != null && _commandCharacteristic != null;

  Future<void> connect() async {
    await FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 8),
      withServices: [Guid(serviceUuid)],
    );

    final results = await FlutterBluePlus.scanResults
        .firstWhere(
          (items) => items.any(
            (result) =>
                result.device.platformName == deviceName ||
                result.advertisementData.advName == deviceName,
          ),
        )
        .timeout(const Duration(seconds: 10));

    await FlutterBluePlus.stopScan();

    final match = results.firstWhere(
      (result) =>
          result.device.platformName == deviceName ||
          result.advertisementData.advName == deviceName,
    );

    final device = match.device;
    await device.connect(timeout: const Duration(seconds: 15), autoConnect: false);
    final services = await device.discoverServices();

    BluetoothCharacteristic? commandCharacteristic;
    for (final service in services) {
      if (service.uuid == Guid(serviceUuid)) {
        for (final characteristic in service.characteristics) {
          if (characteristic.uuid == Guid(commandCharacteristicUuid)) {
            commandCharacteristic = characteristic;
            break;
          }
        }
      }
    }

    if (commandCharacteristic == null) {
      await device.disconnect();
      throw Exception('Característica BLE de comando não encontrada.');
    }

    _device = device;
    _commandCharacteristic = commandCharacteristic;
  }

  Future<void> sendCommand(String command) async {
    final characteristic = _commandCharacteristic;
    if (characteristic == null) {
      throw StateError('O ESP32 não está conectado.');
    }

    await characteristic.write(
      utf8.encode(command),
      withoutResponse: false,
    );
  }

  Future<void> disconnect() async {
    final device = _device;
    _device = null;
    _commandCharacteristic = null;
    if (device != null) await device.disconnect();
  }

  Future<void> dispose() async {
    try {
      await sendCommand('STOP');
    } catch (_) {
      // Pode já estar desconectado.
    }
    await disconnect();
  }
}
