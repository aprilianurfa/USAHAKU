import 'package:flutter/material.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/theme.dart';
import '../../services/printer_service.dart';

class PrinterPage extends StatefulWidget {
  const PrinterPage({Key? key}) : super(key: key);

  @override
  State<PrinterPage> createState() => _PrinterPageState();
}

class _PrinterPageState extends State<PrinterPage> {
  final PrinterService _printerService = PrinterService();
  final BlueThermalPrinter _bluetooth = BlueThermalPrinter.instance;

  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _selectedDevice;
  bool _connected = false;
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _initBluetooth();
  }

  void _initBluetooth() async {
    bool? isConnected = await _printerService.isConnected;
    if (mounted) {
      setState(() {
        _connected = isConnected ?? false;
      });
    }
    _getDevices();
  }

  Future<void> _checkPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    if (statuses[Permission.bluetoothConnect]!.isDenied || 
        statuses[Permission.bluetoothScan]!.isDenied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Izin Bluetooth diperlukan untuk mencari printer"))
        );
      }
    }
  }

  void _getDevices() async {
    setState(() => _isScanning = true);
    try {
      List<BluetoothDevice> devices = await _printerService.getBondedDevices();
      if (mounted) {
        setState(() {
          _devices = devices;
          _isScanning = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text("Pengaturan Printer", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: AppTheme.defaultGradient)),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Connection Status Bar
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            color: _connected ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
            child: Row(
              children: [
                Icon(
                  _connected ? Icons.check_circle : Icons.error_outline,
                  color: _connected ? Colors.green : Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  _connected ? "Printer Terhubung" : "Printer Belum Terhubung",
                  style: TextStyle(
                    color: _connected ? Colors.green.shade800 : Colors.red.shade800,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                if (_isScanning)
                  const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2)),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  "Pilih Perangkat",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                ),
                const SizedBox(height: 12),
                
                _buildDeviceCard(),
                
                const SizedBox(height: 30),
                
                const Text(
                  "Aksi",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                ),
                const SizedBox(height: 12),
                
                _buildActionButton(
                  onPressed: _connected ? _disconnect : (_selectedDevice != null ? _connect : null),
                  icon: _connected ? Icons.bluetooth_disabled : Icons.bluetooth_connected,
                  label: _connected ? "Putuskan Koneksi" : "Hubungkan Printer",
                  color: _connected ? Colors.red : AppTheme.primaryColor,
                ),
                
                const SizedBox(height: 15),
                
                _buildActionButton(
                  onPressed: _connected ? _testPrint : null,
                  icon: Icons.print_rounded,
                  label: "Cetak Test Struk",
                  color: Colors.green.shade600,
                  isOutlined: true,
                ),
                
                const SizedBox(height: 40),
                _buildGuideCard(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _getDevices,
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.refresh_rounded),
      ),
    );
  }

  Widget _buildDeviceCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<BluetoothDevice>(
          isExpanded: true,
          hint: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Text("Cari Printer Thermal..."),
          ),
          value: _selectedDevice,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.primaryColor),
          items: _devices.map((device) {
            return DropdownMenuItem(
              value: device,
              child: ListTile(
                leading: const Icon(Icons.print_outlined, color: Colors.blueGrey),
                title: Text(device.name ?? "Device Unknown", style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(device.address ?? "", style: const TextStyle(fontSize: 12)),
              ),
            );
          }).toList(),
          onChanged: (device) {
            setState(() => _selectedDevice = device);
          },
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
    required Color color,
    bool isOutlined = false,
  }) {
    return Container(
      width: double.infinity,
      height: 55,
      child: isOutlined 
        ? OutlinedButton.icon(
            onPressed: onPressed,
            icon: Icon(icon),
            label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            style: OutlinedButton.styleFrom(
              foregroundColor: color,
              side: BorderSide(color: color, width: 2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          )
        : ElevatedButton.icon(
            onPressed: onPressed,
            icon: Icon(icon),
            label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
    );
  }

  Widget _buildGuideCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: Colors.orange.shade800),
              const SizedBox(width: 10),
              Text("Tips Koneksi", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange.shade800)),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            "1. Hidupkan Bluetooth perangkat thermal printer Anda.\n2. Pastikan printer sudah 'Paired' di menu Bluetooth HP.\n3. Jika tidak muncul, tekan tombol refresh di pojok kanan bawah.",
            style: TextStyle(fontSize: 13, height: 1.5, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  void _connect() async {
    if (_selectedDevice != null) {
      showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
      try {
        await _printerService.connect(_selectedDevice!);
        if (mounted) {
          Navigator.pop(context);
          setState(() => _connected = true);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Printer Berhasil Terhubung!"), backgroundColor: Colors.green));
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal: $e"), backgroundColor: Colors.red));
        }
      }
    }
  }

  void _disconnect() async {
    await _printerService.disconnect();
    if (mounted) setState(() => _connected = false);
  }

  void _testPrint() async {
    await _printerService.testPrint();
  }
}