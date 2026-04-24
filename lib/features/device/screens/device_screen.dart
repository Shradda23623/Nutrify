import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/n_theme.dart';
import '../models/device_model.dart';
import '../services/device_service.dart';

class DeviceScreen extends StatefulWidget {
  const DeviceScreen({super.key});

  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  final DeviceService _service = DeviceService();

  @override
  void initState() {
    super.initState();
    _service.addListener(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    _service.removeListener(_refresh);
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.pageBg,
      appBar: AppBar(
        title: Text('Connect Device',
            style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 20,
                color: context.textPrimary)),
        backgroundColor: context.pageBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: context.textSecondary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status card
            _statusCard(),
            const SizedBox(height: 20),

            // Error message
            if (_service.errorMessage != null) ...[
              _errorBanner(_service.errorMessage!),
              const SizedBox(height: 16),
            ],

            // Connected view OR scan view
            if (_service.status == DeviceStatus.connected)
              _buildConnectedCard()
            else ...[
              _buildScanButton(),
              const SizedBox(height: 20),
              if (_service.status == DeviceStatus.scanning) ...[
                const Center(child: CircularProgressIndicator()),
                const SizedBox(height: 12),
                Center(
                  child: Text('Scanning for nearby devices...',
                      style: TextStyle(
                          fontSize: 13, color: context.textMuted)),
                ),
              ],
              if (_service.scanResults.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Nearby Devices',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: context.textPrimary)),
                const SizedBox(height: 12),
                ..._service.scanResults.map(_buildDeviceTile),
              ] else if (_service.status == DeviceStatus.disconnected &&
                  _service.errorMessage == null) ...[
                const SizedBox(height: 20),
                _buildHint(),
              ],
            ],

            const SizedBox(height: 28),
            _buildSupportedInfo(),
          ],
        ),
      ),
    );
  }

  // ── Status card ────────────────────────────────────────────────────────────

  Widget _statusCard() {
    Color color;
    String label;
    IconData icon;

    switch (_service.status) {
      case DeviceStatus.connected:
        color = AppColors.green;
        label = 'Connected';
        icon = Icons.bluetooth_connected_rounded;
        break;
      case DeviceStatus.scanning:
        color = AppColors.blue;
        label = 'Scanning…';
        icon = Icons.bluetooth_searching_rounded;
        break;
      default:
        color = context.textHint;
        label = 'Not Connected';
        icon = Icons.bluetooth_disabled_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(context.isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: color)),
              const SizedBox(height: 2),
              Text(
                _service.deviceModel?.name ?? 'No device paired',
                style: TextStyle(fontSize: 13, color: context.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Error banner ───────────────────────────────────────────────────────────

  Widget _errorBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: Colors.redAccent, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: const TextStyle(
                    fontSize: 13,
                    color: Colors.redAccent,
                    height: 1.4)),
          ),
        ],
      ),
    );
  }

  // ── Scan button ────────────────────────────────────────────────────────────

  Widget _buildScanButton() {
    final isScanning = _service.status == DeviceStatus.scanning;
    return GestureDetector(
      onTap: isScanning ? _service.stopScan : _service.startScan,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isScanning ? Colors.redAccent : AppColors.primary,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: (isScanning ? Colors.redAccent : AppColors.primary)
                  .withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isScanning
                  ? Icons.stop_rounded
                  : Icons.bluetooth_searching_rounded,
              color: Colors.black87,
            ),
            const SizedBox(width: 8),
            Text(
              isScanning ? 'Stop Scanning' : 'Scan for Devices',
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }

  // ── Device tile ────────────────────────────────────────────────────────────

  Widget _buildDeviceTile(ScanResult result) {
    final name = result.device.platformName.isEmpty
        ? 'Unknown Device'
        : result.device.platformName;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: context.cardDecoration(radius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.green.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child:
                const Icon(Icons.watch_rounded, color: AppColors.green, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: context.textPrimary)),
                Text(result.device.remoteId.str,
                    style:
                        TextStyle(fontSize: 11, color: context.textMuted)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _service.connectDevice(result),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.green.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColors.green.withOpacity(0.4), width: 1),
              ),
              child: const Text('Connect',
                  style: TextStyle(
                      color: AppColors.green, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Connected card ─────────────────────────────────────────────────────────

  Widget _buildConnectedCard() {
    final d = _service.deviceModel!;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: context.cardDecoration(radius: BorderRadius.circular(24)),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.green.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.watch_rounded,
                size: 38, color: AppColors.green),
          ),
          const SizedBox(height: 12),
          Text(d.name,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: context.textPrimary)),
          const SizedBox(height: 4),
          Text(d.type,
              style:
                  TextStyle(fontSize: 13, color: context.textMuted)),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _metric(Icons.directions_walk_rounded,
                  '${d.stepCount ?? 0}', 'Steps', AppColors.green),
              _metric(Icons.favorite_rounded,
                  d.heartRate?.toStringAsFixed(0) ?? '—', 'BPM',
                  Colors.redAccent),
            ],
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _service.disconnect,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  vertical: 12, horizontal: 28),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: Colors.redAccent.withOpacity(0.5)),
              ),
              child: const Text('Disconnect',
                  style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metric(
      IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color, size: 26),
        ),
        const SizedBox(height: 8),
        Text(value,
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: context.textPrimary)),
        Text(label,
            style: TextStyle(fontSize: 12, color: context.textMuted)),
      ],
    );
  }

  // ── Hint when no devices found ─────────────────────────────────────────────

  Widget _buildHint() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppColors.orange.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.lightbulb_outline_rounded,
              size: 24, color: AppColors.orange),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Make sure Bluetooth is ON and your device is in pairing mode. '
              'Tap "Scan for Devices" to discover nearby fitness wearables.',
              style: TextStyle(
                  fontSize: 13, color: context.textSecondary, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  // ── Supported devices info ─────────────────────────────────────────────────

  Widget _buildSupportedInfo() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: context.cardDecoration(radius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Supported Devices',
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: context.textPrimary)),
          const SizedBox(height: 14),
          _supportRow(Icons.watch_rounded, 'Smartwatches (BLE compatible)'),
          _supportRow(
              Icons.fitness_center_rounded, 'Fitness Bands (Mi Band, etc.)'),
          _supportRow(Icons.smartphone_rounded, 'Pedometer via phone sensor'),
          _supportRow(Icons.favorite_rounded, 'Heart rate monitors'),
        ],
      ),
    );
  }

  Widget _supportRow(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.green),
          const SizedBox(width: 10),
          Text(label,
              style:
                  TextStyle(fontSize: 13, color: context.textSecondary)),
        ],
      ),
    );
  }
}
