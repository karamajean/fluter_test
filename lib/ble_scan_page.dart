import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:universal_ble/universal_ble.dart';

/// Nordic UART Service, used by the nRF52840 `peripheral_uart` sample.
const nusServiceUuid = '6e400001-b5a3-f393-e0a9-e50e24dcca9e';

/// Bluetooth SIG company identifier of Nordic Semiconductor.
const nordicCompanyId = 0x0059;

/// Scans for nearby BLE devices and lists them, strongest signal first.
///
/// On Web the browser only lets the user pick one device from its own chooser,
/// so "scan" opens that chooser instead of listing everything around.
class BleScanPage extends StatefulWidget {
  const BleScanPage({super.key});

  @override
  State<BleScanPage> createState() => _BleScanPageState();
}

class _BleScanPageState extends State<BleScanPage> {
  static const _scanDuration = Duration(seconds: 15);

  final _devices = <String, BleDevice>{};
  AvailabilityState? _availability;
  bool _scanning = false;
  bool _nusOnly = false;
  bool _hideUnnamed = true;
  String? _error;

  StreamSubscription<BleDevice>? _scanSub;
  StreamSubscription<AvailabilityState>? _availabilitySub;
  Timer? _stopTimer;
  Timer? _refreshTimer;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    _scanSub = UniversalBle.scanStream.listen((device) {
      _devices[device.deviceId] = device;
      _dirty = true;
    });
    // Advertisements arrive many times per second; repaint at a steady rate.
    _refreshTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (_dirty && mounted) setState(() => _dirty = false);
    });
    if (!kIsWeb) {
      _availabilitySub = UniversalBle.availabilityStream.listen(
        (state) => setState(() => _availability = state),
      );
      UniversalBle.getBluetoothAvailabilityState().then(
        (state) => mounted ? setState(() => _availability = state) : null,
        onError: (Object e) => mounted ? setState(() => _error = '$e') : null,
      );
    }
  }

  @override
  void dispose() {
    _stopTimer?.cancel();
    _refreshTimer?.cancel();
    _scanSub?.cancel();
    _availabilitySub?.cancel();
    if (_scanning) UniversalBle.stopScan();
    super.dispose();
  }

  Future<void> _startScan() async {
    setState(() {
      _devices.clear();
      _error = null;
      _scanning = true;
    });
    try {
      await UniversalBle.startScan(
        scanFilter: _nusOnly ? ScanFilter(withServices: [nusServiceUuid]) : null,
        platformConfig: PlatformConfig(
          web: WebOptions(optionalServices: [nusServiceUuid]),
        ),
      );
      _stopTimer?.cancel();
      _stopTimer = Timer(_scanDuration, _stopScan);
    } catch (e) {
      if (mounted) {
        setState(() {
          _scanning = false;
          _error = '$e';
        });
      }
    }
  }

  Future<void> _stopScan() async {
    _stopTimer?.cancel();
    try {
      await UniversalBle.stopScan();
    } catch (e) {
      _error = '$e';
    }
    if (mounted) setState(() => _scanning = false);
  }

  List<BleDevice> get _visibleDevices {
    final list = _devices.values
        .where((d) => !_hideUnnamed || (d.name?.isNotEmpty ?? false))
        .toList()
      ..sort((a, b) => (b.rssi ?? -999).compareTo(a.rssi ?? -999));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final devices = _visibleDevices;
    final bluetoothOff =
        _availability != null && _availability != AvailabilityState.poweredOn;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Expanded(child: _StatusText(availability: _availability)),
              FilledButton.icon(
                onPressed: bluetoothOff
                    ? null
                    : (_scanning ? _stopScan : _startScan),
                icon: Icon(_scanning ? Icons.stop : Icons.bluetooth_searching),
                label: Text(_scanning ? '停止' : (kIsWeb ? '選擇裝置' : '掃描')),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            children: [
              FilterChip(
                label: const Text('只顯示 Nordic UART'),
                selected: _nusOnly,
                onSelected: _scanning ? null : (v) => setState(() => _nusOnly = v),
              ),
              FilterChip(
                label: const Text('隱藏無名稱'),
                selected: _hideUnnamed,
                onSelected: (v) => setState(() => _hideUnnamed = v),
              ),
            ],
          ),
        ),
        if (_scanning) const LinearProgressIndicator(),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '找到 ${devices.length} 個裝置'
              '${_hideUnnamed ? '（共 ${_devices.length}）' : ''}',
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: devices.length,
            itemBuilder: (context, i) => _DeviceTile(device: devices[i]),
          ),
        ),
      ],
    );
  }
}

class _StatusText extends StatelessWidget {
  const _StatusText({required this.availability});

  final AvailabilityState? availability;

  @override
  Widget build(BuildContext context) {
    final text = kIsWeb
        ? 'Web Bluetooth（由瀏覽器選擇裝置）'
        : switch (availability) {
            null => '檢查藍牙中…',
            AvailabilityState.poweredOn => '藍牙已開啟',
            AvailabilityState.poweredOff => '藍牙已關閉，請先開啟',
            AvailabilityState.unauthorized => '未授權使用藍牙',
            AvailabilityState.unsupported => '此裝置不支援 BLE',
            AvailabilityState.resetting => '藍牙重置中…',
            AvailabilityState.unknown => '藍牙狀態未知',
          };
    return Text(text, style: Theme.of(context).textTheme.bodyMedium);
  }
}

class _DeviceTile extends StatelessWidget {
  const _DeviceTile({required this.device});

  final BleDevice device;

  @override
  Widget build(BuildContext context) {
    final name = device.name?.isNotEmpty ?? false ? device.name! : '(無名稱)';
    final isNus = device.services.contains(nusServiceUuid);
    final isNordic =
        device.manufacturerDataList.any((m) => m.companyId == nordicCompanyId);
    final rssi = device.rssi;

    return ListTile(
      leading: Icon(_signalIcon(rssi)),
      title: Text(name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(device.deviceId, style: const TextStyle(fontFamily: 'monospace')),
          if (isNus || isNordic)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Wrap(
                spacing: 6,
                children: [
                  if (isNus) const _Tag('NUS'),
                  if (isNordic) const _Tag('Nordic'),
                ],
              ),
            ),
        ],
      ),
      trailing: Text(rssi == null ? '' : '$rssi dBm'),
    );
  }

  static IconData _signalIcon(int? rssi) {
    if (rssi == null) return Icons.bluetooth;
    if (rssi >= -60) return Icons.signal_cellular_alt;
    if (rssi >= -80) return Icons.signal_cellular_alt_2_bar;
    return Icons.signal_cellular_alt_1_bar;
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, color: scheme.onTertiaryContainer),
      ),
    );
  }
}
